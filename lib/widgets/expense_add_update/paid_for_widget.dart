import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:kitchenowl/cubits/expense_add_update_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/expense.dart';
import 'package:kitchenowl/models/user.dart';
import 'package:collection/collection.dart';

class PaidForWidget extends StatefulWidget {
  final User user;
  final AddUpdateExpenseCubit cubit;

  const PaidForWidget({
    super.key,
    required this.user,
    required this.cubit,
  });

  @override
  State<PaidForWidget> createState() => _PaidForWidgetState();
}

class _PaidForWidgetState extends State<PaidForWidget> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(
      text: (widget.cubit.state.paidFor
              .firstWhereOrNull(
                (e) => e.userId == widget.user.id,
              )
              ?.factor
              .toString()) ??
          "",
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddUpdateExpenseCubit, AddUpdateExpenseState>(
      bloc: widget.cubit,
      builder: (context, state) {
        final PaidForModel? paidForModel = state.paidFor.firstWhereOrNull(
          (e) => e.userId == widget.user.id,
        );

        return CustomCheckboxListTile(
          title: Text(widget.user.name),
          value: paidForModel != null,
          onChanged: (v) {
            if (v != null) {
              if (v) {
                widget.cubit.addUser(widget.user);
                controller.text = '1';
              } else {
                widget.cubit.removeUser(widget.user);
                controller.text = '';
              }
            }
          },
          subtitle: Text(NumberFormat.simpleCurrency().format(
            (state.amount *
                (paidForModel?.factor ?? 0) /
                state.paidFor.fold(0, (p, v) => p + v.factor)),
          )),
          trailing: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 20,
              maxWidth: 100,
            ),
            child: TextField(
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              controller: controller,
              onTap: () {
                controller.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: controller.text.length,
                );
              },
              onChanged: (t) => widget.cubit.setFactor(
                widget.user,
                int.tryParse(t),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
          ),
        );
      },
    );
  }
}
