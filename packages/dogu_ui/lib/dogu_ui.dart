/// Dogu 디자인 시스템 — 디자인 토큰과 범용 컴포넌트. 앱 데이터(스토어·모델·라우팅)를 모른다.
/// 컴포넌트는 파일 하나에 하나: lib/src/components/{atoms,molecules,brand}/.
library;

export 'src/tokens/tokens.dart';



// atoms
export 'src/components/atoms/mono_text.dart';
export 'src/components/atoms/strike_text.dart';
export 'src/components/atoms/eyebrow.dart';
export 'src/components/atoms/tag.dart';
export 'src/components/atoms/badge_pill.dart';
export 'src/components/atoms/app_button.dart';
export 'src/components/atoms/loading_dots.dart';
export 'src/components/atoms/skeleton_product_card.dart';
export 'src/components/atoms/small_chip.dart';
export 'src/components/atoms/nav_label.dart';
export 'src/components/atoms/icon_box.dart';
export 'src/components/atoms/corner_mark.dart';

// molecules
export 'src/components/molecules/section_head.dart';
export 'src/components/molecules/section_border.dart';
export 'src/components/molecules/soft_divider_block.dart';
export 'src/components/molecules/empty_state_block.dart';
export 'src/components/molecules/summary_line.dart';
export 'src/components/molecules/qty_box.dart';
export 'src/components/molecules/recent_search_tag.dart';
export 'src/components/molecules/stat_grid.dart';
export 'src/components/molecules/quick_filter_row.dart';
export 'src/components/molecules/countdown_timer.dart';
export 'src/components/molecules/preparing_image_surface.dart';
export 'src/components/molecules/neutral_image_surface.dart';
export 'src/components/molecules/product_image.dart';
export 'src/components/molecules/product_card_view.dart';

// brand
export 'src/components/brand/dogu_brand_mark.dart';
export 'src/components/brand/dogu_logo_mark.dart';
export 'src/components/brand/dogu_brand_lockup.dart';
