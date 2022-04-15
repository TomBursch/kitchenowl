import 'dart:io';

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
import 'package:kitchenowl/widgets/confirmation_dialog.dart';
import 'package:kitchenowl/widgets/image_provider.dart';
import 'package:kitchenowl/widgets/select_file.dart';
import 'package:kitchenowl/widgets/text_dialog.dart';
import 'package:kitchenowl/widgets/shopping_item.dart';
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
  final TextEditingController timeController = TextEditingController();
  final TextEditingController sourceController = TextEditingController();
  late AddUpdateRecipeCubit cubit;
  bool isUpdate = false;

  @override
  void initState() {
    super.initState();
    isUpdate = widget.recipe.id != null;
    if (isUpdate) {
      nameController.text = widget.recipe.name;
      descController.text = widget.recipe.description;
      if (widget.recipe.time > 0) {
        timeController.text = widget.recipe.time.toString();
      }
      if (widget.recipe.source.isNotEmpty) {
        sourceController.text = widget.recipe.source;
      }
    }
    cubit = AddUpdateRecipeCubit(widget.recipe);
  }

  @override
  void dispose() {
    cubit.close();
    nameController.dispose();
    descController.dispose();
    timeController.dispose();
    sourceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int crossAxisCount = getValueForScreenType<int>(
      context: context,
      mobile: 3,
      tablet: 6,
      desktop: 9,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(isUpdate
            ? AppLocalizations.of(context)!.recipeEdit
            : AppLocalizations.of(context)!.recipeNew),
        actions: [
          if (!kIsWeb && (Platform.isAndroid || Platform.isIOS))
            BlocBuilder<AddUpdateRecipeCubit, AddUpdateRecipeState>(
              bloc: cubit,
              builder: (context, state) {
                return IconButton(
                  icon: const Icon(Icons.save_rounded),
                  onPressed: state.isValid()
                      ? () async {
                          await cubit.saveRecipe();
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
                    builder: (context, state) => Container(
                      child: IconButton(
                        icon: const Icon(Icons.edit),
                        color: Theme.of(context).colorScheme.secondary,
                        onPressed: () async {
                          File? file = await selectFile(context);
                          if (file != null) {
                            cubit.setImage(file);
                          }
                        },
                      ),
                      margin: const EdgeInsets.all(16),
                      constraints: const BoxConstraints.expand(height: 80),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.secondary,
                          width: 2,
                        ),
                        image: (state.image != null ||
                                cubit.recipe.image != null)
                            ? DecorationImage(
                                fit: BoxFit.cover,
                                opacity: .5,
                                image: state.image != null
                                    ? FileImage(state.image!) as ImageProvider
                                    : getImageProvider(
                                        context,
                                        cubit.recipe.image!,
                                      ),
                              )
                            : null,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
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
                    child: TextField(
                      controller: timeController,
                      onChanged: (s) => cubit.setTime(int.tryParse(s) ?? 0),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.cookingTime,
                        suffix:
                            Text(AppLocalizations.of(context)!.minutesAbbrev),
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
                                        ? Colors.white
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
                              );
                            },
                          );
                          if (res != null && res.isNotEmpty) {
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
                          runSpacing: 7,
                          spacing: 5,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: children + [widget],
                        ),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    child: TextField(
                      controller: descController,
                      onChanged: (s) => cubit.setDescription(s),
                      maxLines: null,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: AppLocalizations.of(context)!.description,
                        hintText:
                            AppLocalizations.of(context)!.writeMarkdownHere,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)!.items + ':',
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
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: BlocBuilder<AddUpdateRecipeCubit, AddUpdateRecipeState>(
                  bloc: cubit,
                  buildWhen: (previous, current) =>
                      !listEquals(previous.items, current.items),
                  builder: (context, state) => SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                      childAspectRatio: 1,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => ShoppingItemWidget(
                        selected: true,
                        item:
                            state.items.where((e) => !e.optional).elementAt(i),
                        onPressed: (RecipeItem item) => cubit.removeItem(item),
                        onLongPressed: (RecipeItem item) =>
                            _editItem(context, item),
                      ),
                      childCount: state.items.where((e) => !e.optional).length,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.itemsOptional + ':',
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
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: BlocBuilder<AddUpdateRecipeCubit, AddUpdateRecipeState>(
                  bloc: cubit,
                  buildWhen: (previous, current) =>
                      !listEquals(previous.items, current.items),
                  builder: (context, state) => SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                      childAspectRatio: 1,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => ShoppingItemWidget(
                        item: state.items.where((e) => e.optional).elementAt(i),
                        onPressed: (RecipeItem item) => cubit.removeItem(item),
                        onLongPressed: (RecipeItem item) =>
                            _editItem(context, item),
                      ),
                      childCount: state.items.where((e) => e.optional).length,
                    ),
                  ),
                ),
              ),
              if (isUpdate)
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverToBoxAdapter(
                    child: ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(
                          Colors.redAccent,
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
                          cubit.removeRecipe();
                          Navigator.of(context).pop(UpdateEnum.deleted);
                        }
                      },
                      child: Text(AppLocalizations.of(context)!.delete),
                    ),
                  ),
                ),
              if (kIsWeb || (!(Platform.isAndroid || Platform.isIOS)))
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, isUpdate ? 0 : 16, 16, 16),
                  sliver: SliverToBoxAdapter(
                    child:
                        BlocBuilder<AddUpdateRecipeCubit, AddUpdateRecipeState>(
                      bloc: cubit,
                      builder: (context, state) => ElevatedButton(
                        onPressed: state.isValid()
                            ? () async {
                                await cubit.saveRecipe();
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
