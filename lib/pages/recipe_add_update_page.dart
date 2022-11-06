import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/recipe_add_update_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/models/update_value.dart';
import 'package:kitchenowl/pages/item_page.dart';
import 'package:kitchenowl/pages/item_search_page.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/widgets/recipe_time_settings.dart';
import 'package:responsive_builder/responsive_builder.dart';

class AddUpdateRecipePage extends StatefulWidget {
  final Recipe recipe;

  const AddUpdateRecipePage({
    Key? key,
    this.recipe = const Recipe(),
  }) : super(key: key);

  @override
  _AddUpdateRecipePageState createState() => _AddUpdateRecipePageState();
}

class _AddUpdateRecipePageState extends State<AddUpdateRecipePage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController yieldsController = TextEditingController();
  final TextEditingController sourceController = TextEditingController();
  late AddUpdateRecipeCubit cubit;
  bool isUpdate = false;
  bool isAdvancedTime = false;

  @override
  void initState() {
    super.initState();
    isUpdate = widget.recipe.id != null;
    nameController.text = widget.recipe.name;
    descController.text = widget.recipe.description;
    if (widget.recipe.yields > 0) {
      yieldsController.text = widget.recipe.yields.toString();
    }
    if (widget.recipe.source.isNotEmpty) {
      sourceController.text = widget.recipe.source;
    }
    cubit = AddUpdateRecipeCubit(widget.recipe);
  }

  @override
  void dispose() {
    cubit.close();
    nameController.dispose();
    descController.dispose();
    yieldsController.dispose();
    sourceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool mobileLayout = getValueForScreenType<bool>(
      context: context,
      mobile: true,
      desktop: false,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(isUpdate
            ? AppLocalizations.of(context)!.recipeEdit
            : AppLocalizations.of(context)!.recipeNew),
        actions: [
          if (mobileLayout)
            BlocBuilder<AddUpdateRecipeCubit, AddUpdateRecipeState>(
              bloc: cubit,
              builder: (context, state) {
                return LoadingIconButton(
                  icon: const Icon(Icons.save_rounded),
                  onPressed: state.isValid()
                      ? () async {
                          await cubit.saveRecipe();
                          if (!mounted) return;
                          Navigator.of(context).pop(UpdateEnum.updated);
                        }
                      : null,
                );
              },
            ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints.expand(width: 1600),
          child: CustomScrollView(
            slivers: [
              SliverList(
                delegate: SliverChildListDelegate([
                  BlocBuilder<AddUpdateRecipeCubit, AddUpdateRecipeState>(
                    bloc: cubit,
                    buildWhen: (previous, current) =>
                        previous.image != current.image,
                    builder: (context, state) => ImageSelector(
                      image: state.image,
                      originalImage: cubit.recipe.image,
                      setImage: cubit.setImage,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: TextField(
                      controller: nameController,
                      onChanged: (s) => cubit.setName(s),
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.name,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: TextField(
                      controller: sourceController,
                      onChanged: (s) => cubit.setSource(s),
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.recipeSource,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: RecipeTimeSettings(
                      recipe: widget.recipe,
                      cubit: cubit,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: TextField(
                      controller: yieldsController,
                      onChanged: (s) => cubit.setYields(int.tryParse(s) ?? 0),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.yields,
                      ),
                    ),
                  ),
                  BlocBuilder<AddUpdateRecipeCubit, AddUpdateRecipeState>(
                    bloc: cubit,
                    buildWhen: (previous, current) =>
                        !setEquals(previous.tags, current.tags) ||
                        !setEquals(
                          previous.selectedTags,
                          current.selectedTags,
                        ),
                    builder: (context, state) {
                      List<Widget> children = state.tags
                          .map<Widget>((e) => FilterChip(
                                label: Text(
                                  e.name,
                                  style: TextStyle(
                                    color: state.selectedTags.contains(e)
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onPrimary
                                        : null,
                                  ),
                                ),
                                selected: state.selectedTags.contains(e),
                                onSelected: (selected) =>
                                    cubit.selectTag(e, selected),
                                selectedColor:
                                    Theme.of(context).colorScheme.secondary,
                              ))
                          .toList();
                      Widget widget = GestureDetector(
                        onTap: () async {
                          final res = await showDialog<String>(
                            context: context,
                            builder: (BuildContext context) {
                              return TextDialog(
                                title: AppLocalizations.of(context)!.addTag,
                                doneText: AppLocalizations.of(context)!.add,
                                hintText: AppLocalizations.of(context)!.name,
                                isInputValid: (s) => s.isNotEmpty,
                              );
                            },
                          );
                          if (res != null) {
                            cubit.addTag(res);
                          }
                        },
                        child: const Icon(Icons.add),
                      );

                      if (children.isEmpty) {
                        children = [
                          Text(AppLocalizations.of(context)!.noTags),
                        ];
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Wrap(
                          runSpacing: 8,
                          spacing: 5,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: children + [widget],
                        ),
                      );
                    },
                  ),
                  BlocListener<AddUpdateRecipeCubit, AddUpdateRecipeState>(
                    bloc: cubit,
                    listenWhen: (previous, current) =>
                        previous.description != current.description,
                    listener: (context, state) {
                      if (descController.text != state.description) {
                        descController.text = state.description;
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: TextField(
                        controller: descController,
                        onChanged: (s) => cubit.setDescription(s),
                        maxLines: null,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(14)),
                          ),
                          labelText: AppLocalizations.of(context)!.description,
                          hintText:
                              AppLocalizations.of(context)!.writeMarkdownHere,
                        ),
                      ),
                    ),
                  ),
                  BlocBuilder<AddUpdateRecipeCubit, AddUpdateRecipeState>(
                    bloc: cubit,
                    buildWhen: (previous, current) =>
                        previous.description != current.description ||
                        previous.source != current.source,
                    builder: (context, state) => state.description.isEmpty &&
                            (Uri.tryParse(state.source)?.hasAbsolutePath ??
                                false)
                        ? Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: LoadingElevatedButton(
                                onPressed: cubit.setDescriptionFromSource,
                                child: Text(
                                  AppLocalizations.of(context)!
                                      .addDescriptionFromSource,
                                ),
                              ),
                            ),
                          )
                        : const SizedBox(height: 16),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${AppLocalizations.of(context)!.items}:',
                            style: Theme.of(context).textTheme.headline6,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => _updateItems(context, false),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
              BlocBuilder<AddUpdateRecipeCubit, AddUpdateRecipeState>(
                bloc: cubit,
                buildWhen: (previous, current) =>
                    !listEquals(previous.items, current.items),
                builder: (context, state) => SliverItemGridList(
                  items: state.items.where((e) => !e.optional).toList(),
                  selected: (item) => true,
                  onPressed: (RecipeItem item) => cubit.removeItem(item),
                  onLongPressed:
                      Nullable((RecipeItem item) => _editItem(context, item)),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${AppLocalizations.of(context)!.itemsOptional}:',
                          style: Theme.of(context).textTheme.headline6,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => _updateItems(context, true),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
              BlocBuilder<AddUpdateRecipeCubit, AddUpdateRecipeState>(
                bloc: cubit,
                buildWhen: (previous, current) =>
                    !listEquals(previous.items, current.items),
                builder: (context, state) => SliverItemGridList(
                  items: state.items.where((e) => e.optional).toList(),
                  selected: (item) => true,
                  onPressed: (RecipeItem item) => cubit.removeItem(item),
                  onLongPressed:
                      Nullable((RecipeItem item) => _editItem(context, item)),
                ),
              ),
              if (isUpdate)
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverToBoxAdapter(
                    child: LoadingElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(
                          Colors.redAccent,
                        ),
                        foregroundColor: MaterialStateProperty.all<Color>(
                          Colors.white,
                        ),
                      ),
                      onPressed: () async {
                        final confirmed = await askForConfirmation(
                          context: context,
                          title: Text(
                            AppLocalizations.of(context)!.recipeDelete,
                          ),
                          content: Text(
                            AppLocalizations.of(context)!
                                .recipeDeleteConfirmation(widget.recipe.name),
                          ),
                        );
                        if (confirmed) {
                          await cubit.removeRecipe();
                          if (!mounted) return;
                          Navigator.of(context).pop(UpdateEnum.deleted);
                        }
                      },
                      child: Text(AppLocalizations.of(context)!.delete),
                    ),
                  ),
                ),
              if (!mobileLayout)
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, isUpdate ? 0 : 16, 16, 16),
                  sliver: SliverToBoxAdapter(
                    child:
                        BlocBuilder<AddUpdateRecipeCubit, AddUpdateRecipeState>(
                      bloc: cubit,
                      builder: (context, state) => LoadingElevatedButton(
                        onPressed: state.isValid()
                            ? () async {
                                await cubit.saveRecipe();
                                if (!mounted) return;
                                Navigator.of(context).pop(UpdateEnum.updated);
                              }
                            : null,
                        child: Text(
                          isUpdate
                              ? AppLocalizations.of(context)!.save
                              : AppLocalizations.of(context)!.recipeAdd,
                        ),
                      ),
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: SizedBox(height: MediaQuery.of(context).padding.bottom),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateItems(BuildContext context, bool optional) async {
    final items =
        await Navigator.of(context).push<List<Item>>(MaterialPageRoute(
              builder: (context) => ItemSearchPage(
                title: AppLocalizations.of(context)!.itemsAdd,
                selectedItems: cubit.state.items
                    .where((e) => e.optional == optional)
                    .map((e) => e.toItemWithDescription())
                    .toList(),
              ),
            )) ??
            [];
    cubit.updateFromItemList(items, optional);
  }

  Future<void> _editItem(BuildContext context, RecipeItem item) async {
    final res = await Navigator.of(context).push<UpdateValue<RecipeItem>>(
      MaterialPageRoute(
        builder: (BuildContext context) => ItemPage(
          item: item,
        ),
      ),
    );
    if (res != null &&
        res.data != null &&
        (res.state == UpdateEnum.deleted || res.state == UpdateEnum.updated)) {
      cubit.updateItem(res.data!);
    }
  }
}
