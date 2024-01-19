import 'package:flutter/widgets.dart';

import 'rendering/sliver_with_pinned_footer.dart';

/// [SliverWithPinnedFooter] adds the ability to have a pinned footer at the bottom of a sliver.
///
/// The sliver will be layed out first and the footer will be added below if there
/// is enough room left in the viewport. If there is not enough room then the footer
/// will be painted on top of the sliver at the bottom of the painted area of the sliver.
///
/// The total size of this sliver will be the paintExtent of the passed in sliver
/// plus the height of the footer.
class SliverWithPinnedFooter extends MultiChildRenderObjectWidget {
  SliverWithPinnedFooter({
    super.key,
    required Widget sliver,
    required Widget footer,
  }) : super(children: [sliver, footer]);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderSliverWithPinnedFooter();
  }
}
