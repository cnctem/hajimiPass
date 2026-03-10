import 'dart:convert';
import 'dart:math';

/// 哈吉米语翻译核心实现代码(自定义Base64方案)
///
/// @author WIFI连接超时
/// @version 1.0
/// Create Time 2025/7/18_21:37

// 常量映射
const Map<String, String> _haJimiConstants = {
  '哈': '哈气！',
};

int _seededHash(String seed) {
  int hash = 0;
  for (final ch in seed.codeUnits) {
    hash = ((hash * 31 + ch) & 0xFFFFFFFF);
  }
  return hash;
}

double Function() _seededRandom(String seed) {
  int hash = _seededHash(seed);
  return () {
    hash = (hash * 9301 + 49297) % 233280;
    return hash / 233280;
  };
}

String _shuffleString(String input, String seed) {
  final rand = _seededRandom(seed);
  final arr = input.split('');
  for (var i = arr.length - 1; i > 0; i--) {
    final j = (rand() * (i + 1)).floor();
    final tmp = arr[i];
    arr[i] = arr[j];
    arr[j] = tmp;
  }
  return arr.join('');
}

String getHaJimiWords(String seed) {
  const baseHaJimiWords =
      '哈基米窝那没撸多阿西噶压库路曼波'
      '哦吗吉利咋酷友达喔哪买奈诺娜美嘎'
      '呀菇啊自一漫步耶哒我找咕马子砸不'
      '南北绿豆椰奶龙瓦塔尼莫欧季里得喵';
  return _shuffleString(baseHaJimiWords, seed);
}

String _encode(String str, String haJimiWords) {
  final input = utf8.encode(str);
  final buffer = StringBuffer();
  var i = 0;

  while (i < input.length) {
    final byte1 = input[i++];
    final byte2 = i < input.length ? input[i++] : null;
    final byte3 = i < input.length ? input[i++] : null;

    final enc1 = byte1 >> 2;
    final enc2 = ((byte1 & 0x03) << 4) | (byte2 == null ? 0 : byte2 >> 4);
    final enc3 = byte2 == null ? 64 : ((byte2 & 0x0F) << 2) | (byte3 == null ? 0 : byte3 >> 6);
    final enc4 = byte3 == null ? 64 : byte3 & 0x3F;

    buffer
      ..write(haJimiWords[enc1])
      ..write(haJimiWords[enc2])
      ..write(enc3 == 64 ? '哩' : haJimiWords[enc3])
      ..write(enc4 == 64 ? '哩' : haJimiWords[enc4]);
  }

  return buffer.toString();
}

String _decode(String base64Str, String haJimiWords) {
  final revMap = <String, int>{};
  final chars = haJimiWords.split('');
  for (var i = 0; i < chars.length; i++) {
    revMap[chars[i]] = i;
  }

  final output = <int>[];
  final runes = base64Str.split('');

  for (var i = 0; i < runes.length; i += 4) {
    final c1 = runes[i];
    final c2 = runes[i + 1];
    final c3 = runes[i + 2];
    final c4 = runes[i + 3];

    final e1 = revMap[c1] ?? 0;
    final e2 = revMap[c2] ?? 0;
    final e3 = c3 == '哩' ? 0 : revMap[c3] ?? 0;
    final e4 = c4 == '哩' ? 0 : revMap[c4] ?? 0;

    output.add((e1 << 2) | (e2 >> 4));
    if (c3 != '哩') output.add(((e2 & 15) << 4) | (e3 >> 2));
    if (c4 != '哩') output.add(((e3 & 3) << 6) | e4);
  }

  return utf8.decode(output);
}

const List<String> _decorations = [
  '哈基米', '窝那没撸多', '阿西噶压', '库路曼波',
  '奈诺娜美嘎', '哦吗吉利', '南北绿豆', '欧莫季里', '椰奶龙',
];

const List<String> _punctuationSet = ['，', '；', '？', '。'];

final Random _random = Random();

String _encodeHaJimi(String text) {
  final runes = text.split('');
  final chunks = <String>[];
  var i = 0;

  while (i < runes.length) {
    final remain = runes.length - i;
    final len = (4 + _random.nextInt(4)).clamp(4, 7);
    final actualLen = remain < len ? remain : len;
    chunks.add(runes.sublist(i, i + actualLen).join(''));
    i += actualLen;
  }

  final result = <String>[];
  var lastPunc = '';

  for (var j = 0; j < chunks.length; j++) {
    final body = chunks[j];
    final prefix = _decorations[_random.nextInt(_decorations.length)];
    final suffix = _decorations[_random.nextInt(_decorations.length)];

    String punctuation;
    if (j == chunks.length - 1) {
      punctuation = '。';
    } else {
      var candidates = List<String>.from(_punctuationSet);
      if (lastPunc == '？' || lastPunc == '。') candidates.remove(lastPunc);
      punctuation = candidates[_random.nextInt(candidates.length)];
    }

    lastPunc = punctuation;
    result.add('$prefix$body$suffix$punctuation');
  }

  return result.join('');
}

String _decodeHaJimi(String encodedText) {
  final decoRegexStr = _decorations.map(RegExp.escape).join('|');
  final punctRegexStr = _punctuationSet.join('');
  final regex = RegExp('($decoRegexStr)(.{1,10})($decoRegexStr)([$punctRegexStr])');

  return regex.allMatches(encodedText).map((m) => m.group(2)!).join('');
}

String humanToHaJimi(String text, String key) {
  return _encodeHaJimi(_encode(text, getHaJimiWords(key)));
}

String haJimiToHuman(String text, String key) {
  final filter = _haJimiConstants[text];
  if (filter != null) return filter;
  return _decode(_decodeHaJimi(text), getHaJimiWords(key));
}
