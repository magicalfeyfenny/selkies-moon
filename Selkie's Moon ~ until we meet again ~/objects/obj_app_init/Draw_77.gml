// Post Draw runs immediately before GameMaker presents the application
// surface. Antialias only fractional fullscreen scaling of the finished image.
var _linear_filter = GamePixelPresentationLinearFilterGet();
global.game_pixel_present_linear = _linear_filter;
gpu_set_texfilter(_linear_filter);
