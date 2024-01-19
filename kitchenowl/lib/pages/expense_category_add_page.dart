import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:kitchenowl/cubits/expense_category_add_update_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/widgets/expense_category_icon.dart';
import 'package:responsive_builder/responsive_builder.dart';

class AddExpenseCategoryPage extends StatefulWidget {
  final Household household;

  const AddExpenseCategoryPage({
    super.key,
    required this.household,
  });

  @override
  _AddExpenseCategoryPageState createState() => _AddExpenseCategoryPageState();
}

class _AddExpenseCategoryPageState extends State<AddExpenseCategoryPage> {
  final TextEditingController nameController = TextEditingController();

  late AddUpdateExpenseCategoryCubit cubit;

  @override
  void initState() {
    super.initState();
    cubit = AddUpdateExpenseCategoryCubit(widget.household);
  }

  @override
  void dispose() {
    cubit.close();
    nameController.dispose();
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
        title: Text(AppLocalizations.of(context)!.addCategory),
        actions: [
          if (mobileLayout)
            BlocBuilder<AddUpdateExpenseCategoryCubit,
                AddUpdateExpenseCategoryState>(
              bloc: cubit,
              builder: (context, state) => LoadingIconButton(
                icon: const Icon(Icons.save_rounded),
                tooltip: AppLocalizations.of(context)!.save,
                onPressed: state.isValid()
                    ? () async {
                        await cubit.saveCategory();
                        if (!mounted) return;
                        Navigator.of(context).pop(UpdateEnum.updated);
                      }
                    : null,
              ),
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
                delegate: SliverChildListDelegate(
                  [
                    BlocBuilder<AddUpdateExpenseCategoryCubit,
                        AddUpdateExpenseCategoryState>(
                      bloc: cubit,
                      builder: (context, state) => SizedBox(
                        height: 130,
                        child: ExpenseCategoryIcon(
                          name: state.name,
                          color: state.color,
                          textScaleFactor: 2,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: nameController,
                        onChanged: (s) => cubit.setName(s),
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.name,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: BlocBuilder<AddUpdateExpenseCategoryCubit,
                          AddUpdateExpenseCategoryState>(
                        bloc: cubit,
                        builder: (context, state) => Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                child: Text(
                                  AppLocalizations.of(context)!.colorSelect,
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text(
                                        AppLocalizations.of(context)!
                                            .colorSelect,
                                      ),
                                      content: SingleChildScrollView(
                                        child: ColorPicker(
                                          enableAlpha: false,
                                          pickerColor: state.color ??
                                              Theme.of(context).primaryColor,
                                          labelTypes: const [],
                                          pickerAreaBorderRadius:
                                              BorderRadius.circular(14),
                                          onColorChanged: (c) =>
                                              cubit.setColor(Nullable(c)),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            if (state.color != null) ...[
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () =>
                                    cubit.setColor(const Nullable.empty()),
                                child: const Icon(Icons.close),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!mobileLayout)
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverToBoxAdapter(
                    child: BlocBuilder<AddUpdateExpenseCategoryCubit,
                        AddUpdateExpenseCategoryState>(
                      bloc: cubit,
                      builder: (context, state) => LoadingElevatedButton(
                        onPressed: state.isValid()
                            ? (() async {
                                await cubit.saveCategory();
                                if (!mounted) return;
                                Navigator.of(context).pop(UpdateEnum.updated);
                              })
                            : null,
                        child: Text(
                          AppLocalizations.of(context)!.addCategory,
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
}
