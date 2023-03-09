import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/settings_cubit.dart';
import 'package:kitchenowl/cubits/settings_server_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/pages/expense_category_add_update_page.dart';
import 'package:kitchenowl/pages/settings/create_user_page.dart';
import 'package:kitchenowl/kitchenowl.dart';

class SettingsServerPage extends StatefulWidget {
  const SettingsServerPage({Key? key}) : super(key: key);

  @override
  _SettingsServerPageState createState() => _SettingsServerPageState();
}

class _SettingsServerPageState extends State<SettingsServerPage> {
  late SettingsServerCubit cubit;

  @override
  void initState() {
    super.initState();
    cubit = SettingsServerCubit();
  }

  @override
  void dispose() {
    cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.server),
      ),
      body: BlocProvider.value(
        value: cubit,
        child: Align(
          alignment: Alignment.topCenter,
          child: Scrollbar(
            child: ConstrainedBox(
              constraints: const BoxConstraints.expand(width: 600),
              child: RefreshIndicator(
                onRefresh: cubit.refresh,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CustomScrollView(
                    primary: true,
                    scrollBehavior: const MaterialScrollBehavior()
                        .copyWith(scrollbars: false),
                    slivers: const [],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
