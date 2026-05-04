import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Brand SVGs are inlined as raw strings to guarantee rendering. The Figma
// exports of these icons used `fill="var(--fill-0, ...)"` CSS-variable syntax
// which `flutter_svg` does not parse, causing the icons to render blank. The
// SVGs below use plain `fill="#hex"` declarations and match the standard
// Google & Facebook brand marks visible in the Figma design.

const String _kGoogleGSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
  <path fill="#FFC107" d="M43.611 20.083H42V20H24v8h11.303c-1.649 4.657-6.08 8-11.303 8-6.627 0-12-5.373-12-12s5.373-12 12-12c3.059 0 5.842 1.154 7.961 3.039l5.657-5.657C34.046 6.053 29.268 4 24 4 12.955 4 4 12.955 4 24s8.955 20 20 20 20-8.955 20-20c0-1.341-.138-2.65-.389-3.917z"/>
  <path fill="#FF3D00" d="m6.306 14.691 6.571 4.819C14.655 15.108 18.961 12 24 12c3.059 0 5.842 1.154 7.961 3.039l5.657-5.657C34.046 6.053 29.268 4 24 4 16.318 4 9.656 8.337 6.306 14.691z"/>
  <path fill="#4CAF50" d="M24 44c5.166 0 9.86-1.977 13.409-5.192l-6.19-5.238C29.211 35.091 26.715 36 24 36c-5.202 0-9.619-3.317-11.283-7.946l-6.522 5.025C9.505 39.556 16.227 44 24 44z"/>
  <path fill="#1976D2" d="M43.611 20.083H42V20H24v8h11.303c-.792 2.237-2.231 4.166-4.087 5.571.001-.001.002-.001.003-.002l6.19 5.238C36.971 39.205 44 34 44 24c0-1.341-.138-2.65-.389-3.917z"/>
</svg>
''';

const String _kFacebookSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
  <path fill="#1877F2" d="M24 4C12.954 4 4 12.954 4 24c0 9.978 7.314 18.254 16.875 19.75V29.797h-5.082V24h5.082v-4.405c0-5.014 2.986-7.782 7.551-7.782 2.186 0 4.472.391 4.472.391v4.914h-2.519c-2.48 0-3.254 1.539-3.254 3.118V24h5.539l-.886 5.797h-4.653V43.75C36.686 42.254 44 33.978 44 24c0-11.046-8.954-20-20-20z"/>
  <path fill="#FFFFFF" d="M29.814 29.797 30.7 24h-5.539v-3.764c0-1.579.774-3.118 3.254-3.118h2.519v-4.914s-2.286-.391-4.472-.391c-4.565 0-7.551 2.768-7.551 7.782V24h-5.082v5.797h5.082V43.75a19.999 19.999 0 0 0 6.286 0V29.797h4.617z"/>
</svg>
''';

/// Multi-color Google "G" mark.
class GoogleGIcon extends StatelessWidget {
  const GoogleGIcon({super.key, this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      _kGoogleGSvg,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

/// Facebook "f" logo, white glyph inside a blue circle.
class FacebookIcon extends StatelessWidget {
  const FacebookIcon({super.key, this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      _kFacebookSvg,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
