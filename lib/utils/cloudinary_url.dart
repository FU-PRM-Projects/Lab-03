/// Dựng URL Cloudinary đã biến đổi (cắt, đổi định dạng, nén) bằng cách chèn
/// phép biến đổi sau `/image/upload/`. Hàm thuần, test không cần mạng.
abstract final class CloudinaryUrl {
  static const String _marker = '/image/upload/';

  /// Ảnh vuông [size] px, cắt theo vùng nổi bật: avatar, ảnh nhóm, thumbnail.
  static String thumb(String url, {required int size}) =>
      _apply(url, 'c_fill,g_auto,w_$size,h_$size,f_auto,q_auto');

  /// Giữ tỉ lệ, rộng tối đa [width] px (không phóng to): ảnh trong nốt.
  static String fit(String url, {required int width}) =>
      _apply(url, 'c_limit,w_$width,f_auto,q_auto');

  /// Không phải URL Cloudinary thì trả nguyên.
  static String _apply(String url, String transformation) {
    if (!url.contains(_marker)) return url;
    return url.replaceFirst(_marker, '$_marker$transformation/');
  }
}
