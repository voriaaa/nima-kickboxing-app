import 'dart:math';

/// Technique library and combos. Descriptions are written for an orthodox
/// stance (left foot forward). Southpaws mirror everything.

enum MoveCategory { stance, punch, kick, defense }

const categoryLabels = {
  MoveCategory.stance: 'پایه',
  MoveCategory.punch: 'مشت',
  MoveCategory.kick: 'لگد و زانو',
  MoveCategory.defense: 'دفاع',
};

const levelLabels = ['مبتدی', 'متوسط', 'پیشرفته'];

class Move {
  const Move({
    required this.id,
    required this.nameFa,
    required this.nameEn,
    required this.category,
    required this.level,
    required this.summary,
    required this.steps,
    required this.tips,
    required this.mistakes,
    this.code,
    this.target,
  });

  final String id;
  final String nameFa;
  final String nameEn;

  /// Punch number used in calls (1 = jab, 2 = cross ...)
  final String? code;
  final MoveCategory category;
  final int level;
  final String summary;
  final List<String> steps;
  final List<String> tips;
  final List<String> mistakes;
  final String? target;
}

const moves = <Move>[
  Move(
    id: 'guard',
    nameFa: 'گارد',
    nameEn: 'STANCE',
    category: MoveCategory.stance,
    level: 0,
    summary:
        'پایه‌ی همه‌ی حرکات. گارد درست یعنی تعادل، دفاع آماده و قدرت ضربه از هر دو دست و پا.',
    steps: [
      'پای چپ جلو، پای راست عقب؛ فاصله‌ی پاها کمی بیشتر از عرض شانه.',
      'پنجه‌ی پای جلو کمی به داخل و پاشنه‌ی پای عقب کمی بالا.',
      'زانوها کمی خم، وزن بین دو پا تقسیم شود.',
      'دست‌ها کنار صورت، آرنج‌ها چسبیده به بدن، چانه پایین.',
      'نگاه به سینه و شانه‌های حریف، نه فقط به دست‌هایش.',
    ],
    tips: [
      'روی پنجه‌ها سبک باش و ریتم داشته باش.',
      'بعد از هر ضربه دست‌ها باید سریع به همین نقطه برگردند.',
    ],
    mistakes: [
      'پاها روی یک خط (تعادل از دست می‌رود).',
      'پایین آمدن دست‌ها هنگام خستگی.',
      'بالا بودن چانه.',
    ],
  ),
  Move(
    id: 'jab',
    nameFa: 'جب',
    nameEn: 'JAB',
    code: '1',
    category: MoveCategory.punch,
    level: 0,
    target: 'صورت یا بدن',
    summary:
        'مشت مستقیم با دست جلو (چپ). سریع‌ترین ضربه؛ برای سنجش فاصله و باز کردن ترکیب‌ها.',
    steps: [
      'از گارد، دست چپ را مستقیم و در خط صاف به سمت هدف بفرست.',
      'در انتهای ضربه مشت را بچرخان تا کف دست رو به زمین باشد.',
      'شانه‌ی چپ بالا می‌آید و چانه را می‌پوشاند.',
      'با همان سرعت دست را در همان مسیر به گارد برگردان.',
    ],
    tips: [
      'می‌توانی همراه جب یک گام کوتاه با پای جلو برداری.',
      'دست راست تمام مدت کنار صورت بماند.',
    ],
    mistakes: [
      'باز کردن آرنج به بیرون (ضربه گرد می‌شود و دیر می‌رسد).',
      'جمع نکردن دست بعد از ضربه.',
      'خم شدن بیش از حد به جلو.',
    ],
  ),
  Move(
    id: 'cross',
    nameFa: 'کراس',
    nameEn: 'CROSS',
    code: '2',
    category: MoveCategory.punch,
    level: 0,
    target: 'چانه یا بدن',
    summary:
        'مشت مستقیم با دست عقب (راست). قدرتش از چرخش پا و لگن می‌آید، نه فقط از دست.',
    steps: [
      'روی پنجه‌ی پای راست بچرخ و پاشنه را بالا بیاور.',
      'لگن و شانه‌ی راست را به جلو بچرخان.',
      'دست راست را مستقیم به هدف بفرست و در انتها مشت را بچرخان.',
      'دست چپ کنار صورت محکم بماند، سپس به گارد برگرد.',
    ],
    tips: [
      'وزن را کمی به پای جلو منتقل کن، ولی از تعادل خارج نشو.',
      'تصور کن مشت از پای عقب شروع می‌شود.',
    ],
    mistakes: [
      'نچرخاندن پای عقب (ضربه بی‌قدرت).',
      'پایین آوردن دست چپ هنگام زدن.',
    ],
  ),
  Move(
    id: 'lhook',
    nameFa: 'هوک چپ',
    nameEn: 'LEAD HOOK',
    code: '3',
    category: MoveCategory.punch,
    level: 0,
    target: 'کنار سر یا دنده‌ها',
    summary:
        'ضربه‌ی گرد با دست جلو. آرنج تقریباً ۹۰ درجه و هم‌سطح مشت؛ قدرت از چرخش بدن.',
    steps: [
      'آرنج چپ را تا ارتفاع شانه بالا بیاور، زاویه‌ی آرنج حدود ۹۰ درجه.',
      'روی پنجه‌ی پای چپ بچرخ و لگن را به راست بچرخان.',
      'دست با بدن یک‌جا می‌چرخد؛ خودِ دست را جدا پرتاب نکن.',
      'بعد از برخورد، دست را کوتاه به گارد برگردان.',
    ],
    tips: [
      'مشت می‌تواند عمودی یا افقی باشد؛ هر کدام که مچ راحت‌تر است.',
      'هوک بعد از کراس طبیعی‌ترین ادامه است.',
    ],
    mistakes: [
      'باز کردن زیاد دست (ضربه از دور دیده می‌شود).',
      'نچرخاندن پای جلو.',
    ],
  ),
  Move(
    id: 'rhook',
    nameFa: 'هوک راست',
    nameEn: 'REAR HOOK',
    code: '4',
    category: MoveCategory.punch,
    level: 1,
    target: 'کنار سر یا دنده‌ها',
    summary:
        'ضربه‌ی گرد با دست عقب. مسیرش طولانی‌تر و پرقدرت‌تر است؛ معمولاً بعد از جب یا هوک چپ.',
    steps: [
      'پای راست را روی پنجه بچرخان و لگن را به چپ بچرخان.',
      'آرنج راست را تا ارتفاع شانه بالا بیاور.',
      'دست را با چرخش بدن در یک کمان کوتاه به هدف برسان.',
      'دست چپ کنار صورت بماند و سریع به گارد برگرد.',
    ],
    tips: ['کوتاه و نزدیک بزن؛ هوک راستِ بلند به‌راحتی دیده می‌شود.'],
    mistakes: [
      'عقب کشیدن دست قبل از ضربه (لو دادن ضربه).',
      'باز ماندن صورت سمت چپ.',
    ],
  ),
  Move(
    id: 'lupper',
    nameFa: 'آپرکات چپ',
    nameEn: 'LEAD UPPERCUT',
    code: '5',
    category: MoveCategory.punch,
    level: 1,
    target: 'چانه یا شکم',
    summary: 'ضربه‌ی رو به بالا با دست جلو؛ مخصوص فاصله‌ی نزدیک.',
    steps: [
      'زانوها را کمی خم کن و وزن را روی پای چپ بیاور.',
      'دست چپ کمی پایین می‌آید، کف دست رو به خودت.',
      'با باز کردن زانوها و چرخش لگن، مشت را رو به بالا بفرست.',
      'مشت از جلوی بدن بالا می‌رود، نه از کنار.',
    ],
    tips: ['دست را زیاد پایین نبر؛ چند سانت کافی است.'],
    mistakes: ['ضربه فقط با دست، بدون پا.', 'باز شدن گارد سمت چپ.'],
  ),
  Move(
    id: 'rupper',
    nameFa: 'آپرکات راست',
    nameEn: 'REAR UPPERCUT',
    code: '6',
    category: MoveCategory.punch,
    level: 1,
    target: 'چانه یا شکم',
    summary: 'آپرکات با دست عقب؛ یکی از سنگین‌ترین ضربه‌ها در فاصله‌ی نزدیک.',
    steps: [
      'کمی زانوها را خم کن و وزن را روی پای راست ببر.',
      'پای راست را روی پنجه بچرخان و لگن را به جلو بیاور.',
      'مشت راست را با کف دست رو به خودت، رو به بالا بفرست.',
      'دست چپ از صورت محافظت کند، سپس به گارد برگرد.',
    ],
    tips: ['بعد از آپرکات راست، هوک چپ بسیار طبیعی می‌نشیند.'],
    mistakes: ['خم شدن زیاد و از دست دادن تعادل.'],
  ),
  Move(
    id: 'teep',
    nameFa: 'تیپ (فرانت کیک)',
    nameEn: 'TEEP',
    category: MoveCategory.kick,
    level: 0,
    target: 'شکم یا لگن',
    summary:
        'لگد هل‌دادنی با پای جلو. برای دور کردن حریف، کنترل فاصله و قطع حمله‌اش.',
    steps: [
      'زانوی پای چپ را بالا و رو به جلو بیاور.',
      'پنجه‌ی پا را بالا بگیر تا با کف پا (پنجه) ضربه بزنی.',
      'لگن را جلو بده و پا را صاف به سمت شکم حریف باز کن.',
      'پا را سریع جمع کن و در گارد فرود بیاور.',
    ],
    tips: ['بالاتنه کمی عقب می‌رود؛ دست‌ها همچنان بالا.'],
    mistakes: [
      'باز کردن پا بدون بالا آوردن زانو (ضربه ضعیف).',
      'پایین انداختن دست‌ها.',
    ],
  ),
  Move(
    id: 'lowkick',
    nameFa: 'لوکیک راست',
    nameEn: 'LOW KICK',
    category: MoveCategory.kick,
    level: 0,
    target: 'بیرون یا داخل ران حریف',
    summary: 'لگد چرخشی با پای عقب به ران حریف؛ با ساق پا ضربه بزن، نه با پشت پا.',
    steps: [
      'یک گام کوتاه با پای چپ به بیرون (۴۵ درجه) بردار.',
      'روی پنجه‌ی پای چپ بچرخ تا پاشنه رو به حریف شود.',
      'لگن را کامل بچرخان و پای راست را در یک کمان رو به پایین بفرست.',
      'دست راست برای تعادل پایین و عقب می‌رود، دست چپ صورت را می‌پوشاند.',
    ],
    tips: ['هدف حدود ۱۰ سانت بالای زانو است.', 'بعد از ضربه پا را عقب برگردان.'],
    mistakes: [
      'نچرخاندن پای تکیه‌گاه (فشار به زانو).',
      'ضربه با پنجه یا مچ پا.',
    ],
  ),
  Move(
    id: 'midkick',
    nameFa: 'میدل کیک راست',
    nameEn: 'BODY KICK',
    category: MoveCategory.kick,
    level: 1,
    target: 'دنده‌ها و پهلو',
    summary: 'لگد چرخشی با پای عقب به بدن. یکی از پرقدرت‌ترین ضربه‌های کیک‌بوکس.',
    steps: [
      'گام کوتاه به بیرون با پای چپ و چرخش روی پنجه.',
      'لگن را کامل بچرخان؛ زانو بالا و رو به جلو می‌آید.',
      'ساق پا را در ارتفاع دنده‌ها به هدف برسان.',
      'دست راست پایین و عقب برای تعادل، سپس به گارد برگرد.',
    ],
    tips: ['پا را مثل یک چوب‌دستی یکپارچه بچرخان، فقط ساق را پرتاب نکن.'],
    mistakes: ['تکیه دادن زیاد به عقب.', 'نچرخاندن لگن.'],
  ),
  Move(
    id: 'rhigh',
    nameFa: 'های کیک راست',
    nameEn: 'HIGH KICK',
    category: MoveCategory.kick,
    level: 1,
    target: 'سر و گردن',
    summary: 'لگد چرخشی پای عقب به سر. نیاز به انعطاف، تعادل و چرخش کامل لگن دارد.',
    steps: [
      'گام به بیرون با پای چپ و چرخش کامل روی پنجه.',
      'لگن و زانو را بالا بیاور؛ بالاتنه کمی به عقب متمایل می‌شود.',
      'ساق پا را در یک کمان رو به بالا به سمت سر بفرست.',
      'دست چپ کنار صورت، دست راست برای تعادل پایین.',
    ],
    tips: ['قبل از تمرین های کیک، کشش کامل لگن و همسترینگ را انجام بده.'],
    mistakes: ['ضربه بدون گرم کردن کافی.', 'پایین افتادن دست جلو.'],
  ),
  Move(
    id: 'lhigh',
    nameFa: 'های کیک چپ',
    nameEn: 'SWITCH HIGH KICK',
    category: MoveCategory.kick,
    level: 2,
    target: 'سر',
    summary:
        'لگد چرخشی با پای جلو بعد از تعویض سریع پا. بعد از ضربات راست (مثل هوک راست) عالی می‌نشیند.',
    steps: [
      'با یک پرش کوتاه جای پاها را عوض کن (پای راست جلو).',
      'بلافاصله روی پنجه‌ی پای راست بچرخ.',
      'پای چپ را در کمان رو به بالا به سر حریف بفرست.',
      'سریع به گارد اصلی برگرد.',
    ],
    tips: ['تعویض پا باید کوتاه و بی‌صدا باشد تا حریف متوجه نشود.'],
    mistakes: ['تعویض پای بلند و آهسته.', 'از دست دادن تعادل بعد از ضربه.'],
  ),
  Move(
    id: 'sidekick',
    nameFa: 'ساید کیک',
    nameEn: 'SIDE KICK',
    category: MoveCategory.kick,
    level: 2,
    target: 'بدن یا ران',
    summary: 'لگد بغل با پای جلو؛ ضربه با پاشنه و لبه‌ی پا، بدن از پهلو رو به حریف.',
    steps: [
      'زانوی چپ را جمع کن و بالا بیاور، پاشنه رو به حریف.',
      'روی پای راست بچرخ تا پهلویت رو به حریف شود.',
      'پا را صاف باز کن و با پاشنه ضربه بزن.',
      'پا را جمع کن و در گارد فرود بیاور.',
    ],
    tips: ['بالاتنه به عقب متمایل می‌شود تا تعادل حفظ شود.'],
    mistakes: ['ضربه با پنجه به جای پاشنه.'],
  ),
  Move(
    id: 'knee',
    nameFa: 'زانو',
    nameEn: 'KNEE',
    category: MoveCategory.kick,
    level: 1,
    target: 'شکم و پهلو (در فاصله‌ی نزدیک)',
    summary: 'ضربه‌ی زانوی پای عقب؛ در فاصله‌ی خیلی نزدیک یا بعد از گرفتن حریف.',
    steps: [
      'دست‌ها را جلو ببر (کنترل سر یا شانه‌ی حریف).',
      'روی پنجه‌ی پای چپ بایست و لگن را به جلو هل بده.',
      'زانوی راست را با قدرت رو به بالا و جلو بیاور.',
      'پنجه‌ی پا رو به پایین، سپس به گارد برگرد.',
    ],
    tips: ['قدرت از جلو دادن لگن است، نه فقط بالا آوردن پا.'],
    mistakes: ['خم شدن به جلو روی زانو.'],
  ),
  Move(
    id: 'slip',
    nameFa: 'اسلیپ',
    nameEn: 'SLIP',
    category: MoveCategory.defense,
    level: 0,
    summary:
        'جاخالی دادن سر از مسیر مشت مستقیم با یک حرکت کوتاه بدن، بدون عقب رفتن.',
    steps: [
      'زانوها را کمی خم کن.',
      'بالاتنه را کوتاه به یک طرف و کمی جلو ببر تا سر از خط مشت خارج شود.',
      'دست‌ها کنار صورت بمانند.',
      'بلافاصله با یک ضربه جواب بده (مثلاً کراس یا هوک).',
    ],
    tips: ['حرکت کوچک باشد؛ فقط به اندازه‌ای که مشت رد شود.'],
    mistakes: ['حرکت زیاد و از دست دادن تعادل.', 'بستن چشم.'],
  ),
  Move(
    id: 'duck',
    nameFa: 'داک (زیر رفتن)',
    nameEn: 'DUCK',
    category: MoveCategory.defense,
    level: 1,
    summary: 'رفتن زیر ضربات گرد (هوک یا های کیک) با خم کردن زانوها.',
    steps: [
      'زانوها را خم کن و پایین برو؛ کمر نسبتاً صاف بماند.',
      'نگاهت به حریف باشد.',
      'دست‌ها بالا و کنار صورت.',
      'از پایین با آپرکات یا هوک جواب بده.',
    ],
    tips: ['با زانو پایین برو، نه با خم کردن کمر.'],
    mistakes: ['نگاه به زمین.', 'پایین آمدن دست‌ها.'],
  ),
  Move(
    id: 'leanback',
    nameFa: 'عقب‌کشی',
    nameEn: 'LEAN BACK',
    category: MoveCategory.defense,
    level: 1,
    summary: 'عقب بردن سر و بالاتنه برای فرار از مشت یا های کیک، بدون جابجایی پاها.',
    steps: [
      'وزن را روی پای عقب ببر.',
      'بالاتنه و سر را کوتاه به عقب ببر.',
      'دست‌ها بالا بمانند.',
      'سریع برگرد و با کراس یا لوکیک جواب بده.',
    ],
    tips: ['فاصله‌ی حرکت فقط چند سانتی‌متر کافی است.'],
    mistakes: ['عقب رفتن بیش از حد و افتادن.'],
  ),
  Move(
    id: 'check',
    nameFa: 'چک ساق (بلاک لگد)',
    nameEn: 'SHIN CHECK',
    category: MoveCategory.defense,
    level: 1,
    summary: 'دفاع در برابر لوکیک و میدل کیک با بالا آوردن ساق پا.',
    steps: [
      'زانوی پای جلو را بالا بیاور و کمی به بیرون بچرخان.',
      'ساق پا عمودی و محکم، پنجه کمی بالا.',
      'دست هم‌سمت کنار سر بماند.',
      'پا را پایین بگذار و بلافاصله جواب بده.',
    ],
    tips: ['ساق را به سمت لگد حریف بچرخان تا ضربه روی ساق تو بنشیند.'],
    mistakes: ['دیر بالا آوردن پا.', 'خم شدن به عقب.'],
  ),
];

Move moveById(String id) => moves.firstWhere((m) => m.id == id);

/// Short label used inside combo chips: «1 جب»
String moveLabel(String id) {
  final m = moveById(id);
  return m.code == null ? m.nameFa.split(' (').first : '${m.code} ${m.nameFa}';
}

class Combo {
  const Combo({
    required this.id,
    required this.level,
    required this.moveIds,
    this.note,
  });

  final String id;
  final int level;
  final List<String> moveIds;
  final String? note;

  String get title => moveIds.map((id) => moveById(id).nameFa.split(' (').first).join(' + ');

  /// e.g. 1-2-3 + LOW KICK
  String get codes => moveIds
      .map((id) => moveById(id).code ?? moveById(id).nameEn)
      .join(' · ');
}

const combos = <Combo>[
  // Beginner
  Combo(id: 'c1', level: 0, moveIds: ['jab', 'cross'], note: 'پایه‌ای‌ترین ترکیب؛ سرعت و برگشت دست را تمرین کن.'),
  Combo(id: 'c2', level: 0, moveIds: ['jab', 'jab', 'cross'], note: 'جب دوم کمی جلوتر برود و فاصله را ببندد.'),
  Combo(id: 'c3', level: 0, moveIds: ['jab', 'cross', 'lhook'], note: 'هوک بعد از کراس با برگشت وزن روی پای جلو.'),
  Combo(id: 'c4', level: 0, moveIds: ['jab', 'lowkick'], note: 'جب حواس حریف را بالا می‌برد، لوکیک پایین می‌نشیند.'),
  Combo(id: 'c5', level: 0, moveIds: ['teep', 'cross'], note: 'تیپ حریف را متوقف می‌کند، کراس با برگشت پا.'),
  Combo(id: 'c6', level: 0, moveIds: ['cross', 'lhook', 'lowkick']),
  // Intermediate
  Combo(id: 'c7', level: 1, moveIds: ['jab', 'cross', 'lhook', 'lowkick'], note: 'ترکیب کلاسیک «دست‌ها بالا، پا پایین».'),
  Combo(id: 'c8', level: 1, moveIds: ['jab', 'cross', 'rhook', 'lhigh'], note: 'بعد از هوک راست وزن روی پای راست است؛ های کیک چپ طبیعی می‌نشیند.'),
  Combo(id: 'c9', level: 1, moveIds: ['jab', 'cross', 'lhook', 'midkick']),
  Combo(id: 'c10', level: 1, moveIds: ['slip', 'cross', 'lhook'], note: 'جاخالی از جب حریف و ضدحمله.'),
  Combo(id: 'c11', level: 1, moveIds: ['rupper', 'lhook', 'cross'], note: 'ترکیب فاصله‌ی نزدیک (6-3-2).'),
  Combo(id: 'c12', level: 1, moveIds: ['jab', 'cross', 'knee']),
  // Advanced
  Combo(id: 'c13', level: 2, moveIds: ['jab', 'cross', 'lhook', 'cross', 'lhigh']),
  Combo(id: 'c14', level: 2, moveIds: ['lowkick', 'cross', 'lhook', 'rhigh'], note: 'لوکیک گارد حریف را پایین می‌آورد، های کیک تمام‌کننده است.'),
  Combo(id: 'c15', level: 2, moveIds: ['check', 'cross', 'lhook', 'midkick'], note: 'دفاع از لوکیک و ضدحمله‌ی فوری.'),
  Combo(id: 'c16', level: 2, moveIds: ['duck', 'lhook', 'rupper', 'lhook', 'rhigh']),
  Combo(id: 'c17', level: 2, moveIds: ['leanback', 'cross', 'lowkick']),
  Combo(id: 'c18', level: 2, moveIds: ['jab', 'teep', 'cross', 'sidekick']),
];

/// Combos that contain a given move.
List<Combo> combosWith(String moveId) =>
    combos.where((c) => c.moveIds.contains(moveId)).toList();

/// Same combo for the whole day, different every day.
Combo comboOfTheDay(DateTime now) {
  final day = DateTime(now.year, now.month, now.day)
          .difference(DateTime(2024))
          .inDays;
  return combos[day % combos.length];
}

/// Random but natural combo: punches alternate sides, a kick from the
/// opposite side may finish it, defense may open it at higher levels.
List<String> randomCombo(Random r, int level) {
  const leadPunches = [
    ['jab', 'lhook'],
    ['jab', 'lhook', 'lupper'],
    ['jab', 'lhook', 'lupper'],
  ];
  const rearPunches = [
    ['cross'],
    ['cross', 'rhook', 'rupper'],
    ['cross', 'rhook', 'rupper'],
  ];
  const rearKicks = [
    ['lowkick'],
    ['lowkick', 'midkick', 'rhigh', 'knee'],
    ['lowkick', 'midkick', 'rhigh', 'knee'],
  ];
  const leadKicks = [
    ['teep'],
    ['teep', 'lhigh'],
    ['teep', 'lhigh', 'sidekick'],
  ];
  const defenses = ['slip', 'duck', 'check', 'leanback'];

  final out = <String>[];
  if (level >= 1 && r.nextDouble() < 0.3) {
    out.add(defenses[r.nextInt(level >= 2 ? 4 : 2)]);
  }
  final punches = 2 + r.nextInt(level + 2); // 2..level+3
  var lead = r.nextDouble() < 0.8; // usually start with the lead hand
  for (var i = 0; i < punches; i++) {
    final pool = lead ? leadPunches[level] : rearPunches[level];
    // the first lead punch is usually a jab
    out.add(i == 0 && lead && r.nextDouble() < 0.7 ? 'jab' : pool[r.nextInt(pool.length)]);
    lead = !lead;
  }
  if (r.nextDouble() < (level == 0 ? 0.5 : 0.75)) {
    // `lead` now says which side is free (opposite of the last punch)
    final pool = lead ? leadKicks[level] : rearKicks[level];
    out.add(pool[r.nextInt(pool.length)]);
  }
  return out;
}
