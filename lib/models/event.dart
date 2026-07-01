import 'package:flutter/material.dart';

/// Тип билета внутри события (VIP / Standard / Student и т.д.)
class TicketType {
  final String name;
  final String nameAm;
  final int price; // в драмах (AMD)
  final String? note;

  const TicketType({
    required this.name, 
    required this.nameAm,
    required this.price, 
    this.note
  });
  
  /// Возвращает название на выбранном языке
  String getName(bool isArmenian) => isArmenian ? nameAm : name;
}

/// Категория события для фильтров-чипов.
enum EventCategory { all, concert, theatre, festival, conference, exhibition }

/// Статус события (Задача 4): активно / отменено организатором /
/// перенесено на новую дату. Билеты наследуют этот статус.
enum EventStatus { active, cancelled, rescheduled }

extension EventCategoryX on EventCategory {
  /// Стабильный ключ для API и локализации (не зависит от языка).
  String get key {
    switch (this) {
      case EventCategory.all:
        return 'all';
      case EventCategory.concert:
        return 'concert';
      case EventCategory.theatre:
        return 'theatre';
      case EventCategory.festival:
        return 'festival';
      case EventCategory.conference:
        return 'conference';
      case EventCategory.exhibition:
        return 'exhibition';
    }
  }

  /// Русский лейбл по умолчанию (для мест без контекста локализации).
  String get label {
    switch (this) {
      case EventCategory.all:
        return 'Все';
      case EventCategory.concert:
        return 'Концерты';
      case EventCategory.theatre:
        return 'Театр';
      case EventCategory.festival:
        return 'Фестивали';
      case EventCategory.conference:
        return 'Конференции';
      case EventCategory.exhibition:
        return 'Выставки';
    }
  }

  IconData get icon {
    switch (this) {
      case EventCategory.all:
        return Icons.apps_rounded;
      case EventCategory.concert:
        return Icons.music_note_rounded;
      case EventCategory.theatre:
        return Icons.theater_comedy_rounded;
      case EventCategory.festival:
        return Icons.celebration_rounded;
      case EventCategory.conference:
        return Icons.mic_external_on_rounded;
      case EventCategory.exhibition:
        return Icons.museum_rounded;
    }
  }
}

/// Модель события.
class Event {
  final String id;
  final String title;
  final String titleAm;
  final String venue;
  final String venueAm;
  final String city;
  final double lat;
  final double lng;
  final DateTime date;
  final EventCategory category;
  final int priceFrom; // в драмах
  final Color cover; // цвет-подложка (виден при загрузке/ошибке фото)
  final String description;
  final String descriptionAm;
  final List<TicketType> ticketTypes;
  final bool featured;

  /// Refund Guarantee (PRD §8, Сценарий В): по умолчанию билеты невозвратны,
  /// организатор может включить расширенный возврат для конкретного события.
  final bool refundGuarantee;

  /// До скольких часов до начала события доступен возврат при включённом
  /// [refundGuarantee]. Настраивается организатором (PRD §8).
  final int refundUntilHours;

  /// Реальное фото-обложка (Wikimedia). Если null — показывается
  /// фирменный градиент с иконкой категории.
  final String? imageUrl;

  /// Статус события (Задача 4): active / cancelled / rescheduled.
  final EventStatus status;

  /// Новая дата при [EventStatus.rescheduled] (иначе null).
  final DateTime? newDate;

  /// Срок принятия решения покупателем при переносе (PRD: 72 часа).
  /// После истечения без ответа билет остаётся действительным на новую
  /// дату (opt-out). null, если событие не перенесено.
  final DateTime? decisionDeadline;

  /// Кол-во рабочих дней авто-возврата при отмене события (по умолчанию 7).
  final int refundDaysOnCancel;

  const Event({
    required this.id,
    required this.title,
    required this.titleAm,
    required this.venue,
    required this.venueAm,
    required this.city,
    this.lat = 40.1792,
    this.lng = 44.4991,
    required this.date,
    required this.category,
    required this.priceFrom,
    required this.cover,
    required this.description,
    required this.descriptionAm,
    required this.ticketTypes,
    this.featured = false,
    this.refundGuarantee = false,
    this.refundUntilHours = 24,
    this.imageUrl,
    this.status = EventStatus.active,
    this.newDate,
    this.decisionDeadline,
    this.refundDaysOnCancel = 7,
  });
  
  /// Возвращает название на выбранном языке
  String getTitle(bool isArmenian) => isArmenian ? titleAm : title;
  
  /// Возвращает описание на выбранном языке
  String getDescription(bool isArmenian) => isArmenian ? descriptionAm : description;
  
  /// Возвращает место проведения на выбранном языке
  String getVenue(bool isArmenian) => isArmenian ? venueAm : venue;

  /// Событие отменено организатором.
  bool get isCancelled => status == EventStatus.cancelled;

  /// Событие перенесено на новую дату.
  bool get isRescheduled => status == EventStatus.rescheduled;

  /// Копия с изменённым статусом/датами (для админки/API).
  Event copyWith({
    EventStatus? status,
    DateTime? date,
    DateTime? newDate,
    DateTime? decisionDeadline,
    int? refundDaysOnCancel,
  }) {
    return Event(
      id: id,
      title: title,
      titleAm: titleAm,
      venue: venue,
      venueAm: venueAm,
      city: city,
      lat: lat,
      lng: lng,
      date: date ?? this.date,
      category: category,
      priceFrom: priceFrom,
      cover: cover,
      description: description,
      descriptionAm: descriptionAm,
      ticketTypes: ticketTypes,
      featured: featured,
      refundGuarantee: refundGuarantee,
      refundUntilHours: refundUntilHours,
      imageUrl: imageUrl,
      status: status ?? this.status,
      newDate: newDate ?? this.newDate,
      decisionDeadline: decisionDeadline ?? this.decisionDeadline,
      refundDaysOnCancel: refundDaysOnCancel ?? this.refundDaysOnCancel,
    );
  }

  String get dateLabel {
    const months = [
      'янв', 'фев', 'мар', 'апр', 'мая', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
    ];
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '${date.day} ${months[date.month - 1]} · $h:$m';
  }

  String get priceLabel => 'от ${_money(priceFrom)} ֏';
}

String money(int v) => _money(v);
String _money(int v) {
  final s = v.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return buf.toString();
}

/// Демо-данные (моки) на основе реальных событий и площадок Армении.
/// Используются в режиме без backend (Api.instance = MockTicketsApi).
/// Фото — Wikimedia Commons (отдаются с CORS, грузятся и в web-сборке).
class MockData {
  static const _imgKaleo =
      'https://upload.wikimedia.org/wikipedia/commons/f/f5/20180603_N%C3%BCrnberg_Rock_im_Park_Kaleo_0212.jpg';
  static const _imgMeladze =
      'https://upload.wikimedia.org/wikipedia/commons/e/e1/Valeriy_Meladze_photoshooting_at_Laima_Rendez_Vous_Jurmala_2017.jpg';
  static const _imgPetrenko =
      'https://upload.wikimedia.org/wikipedia/commons/a/a4/Vasily_Eduardovich_Petrenko.jpg';
  static const _imgGerstein =
      'https://upload.wikimedia.org/wikipedia/commons/e/ea/Kirill_Gerstein_2009.jpg';
  static const _imgOpera =
      'https://upload.wikimedia.org/wikipedia/commons/thumb/1/19/%C3%93pera%2C_Erev%C3%A1n%2C_Armenia%2C_2016-10-03%2C_DD_12.jpg/1280px-%C3%93pera%2C_Erev%C3%A1n%2C_Armenia%2C_2016-10-03%2C_DD_12.jpg';
  static const _imgDemirchyan =
      'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5a/Karen_Demirchyan_Sports_and_Concerts_Complex_shot_from_air%2C_May_2019.jpg/1280px-Karen_Demirchyan_Sports_and_Concerts_Complex_shot_from_air%2C_May_2019.jpg';

  // Часто используемые площадки (RU + AM).
  static const _demirchyanRu = 'Спорткомплекс им. Карена Демирчяна';
  static const _demirchyanAm = 'Կարեն Դեմիրճյանի անվ. մարզահամերգային համալիր';
  static const _khachaturyanRu = 'Концертный зал им. Арама Хачатуряна';
  static const _khachaturyanAm = 'Արամ Խաչատրյանի անվ. համերգասրահ';

  static final List<Event> events = [
    // 1. KALEO — исландский рок.
    Event(
      id: 'e1',
      title: 'KALEO в Ереване',
      titleAm: 'KALEO Երևանում',
      venue: _demirchyanRu,
      venueAm: _demirchyanAm,
      city: 'Ереван',
      lat: 40.1872, lng: 44.4856,
      date: DateTime(2026, 7, 18, 20, 0),
      category: EventCategory.concert,
      priceFrom: 8000,
      cover: const Color(0xFF1C1C24),
      featured: true,
      refundGuarantee: true,
      refundUntilHours: 48,
      imageUrl: _imgKaleo,
      description:
          'Исландская рок-группа KALEO впервые в Ереване — фирменный блюз-рок '
          'и хиты «Way Down We Go» и «No Good» вживую.',
      descriptionAm:
          'Իսլանդական ռոք-խումբ KALEO-ն առաջին անգամ Երևանում՝ ֆիրմային '
          'բլյուզ-ռոք և «Way Down We Go», «No Good» հիթերը կենդանի կատարմամբ։',
      ticketTypes: const [
        TicketType(name: 'Фан-зона', nameAm: 'Ֆան-գոտի', price: 8000, note: 'Стоячие места'),
        TicketType(name: 'Танцпол', nameAm: 'Պարահրապարակ', price: 14000, note: 'У сцены'),
        TicketType(name: 'VIP', nameAm: 'VIP', price: 28000, note: 'Лучшие места'),
      ],
    ),
    // 2. Валерий Меладзе.
    Event(
      id: 'e2',
      title: 'Валерий Меладзе',
      titleAm: 'Վալերի Մելաձե',
      venue: _demirchyanRu,
      venueAm: _demirchyanAm,
      city: 'Ереван',
      lat: 40.1872, lng: 44.4856,
      date: DateTime(2026, 11, 28, 20, 0),
      category: EventCategory.concert,
      priceFrom: 12000,
      cover: const Color(0xFF2A1A4A),
      imageUrl: _imgMeladze,
      description:
          'Большой сольный концерт Валерия Меладзе — все главные хиты за '
          'тридцать лет и новая программа в одном вечере.',
      descriptionAm:
          'Վալերի Մելաձեի մեծ մենահամերգը՝ երեսնամյա բոլոր գլխավոր հիթերը '
          'և նոր ծրագիրը մեկ երեկոյի մեջ։',
      ticketTypes: const [
        TicketType(name: 'Балкон', nameAm: 'Բալկոն', price: 12000),
        TicketType(name: 'Партер', nameAm: 'Պարտեր', price: 22000),
        TicketType(name: 'VIP', nameAm: 'VIP', price: 45000, note: 'Первые ряды'),
      ],
    ),
    // 3. Василий Петренко и АГФО.
    Event(
      id: 'e3',
      title: 'Василий Петренко и АГФО',
      titleAm: 'Վասիլի Պետրենկո և ՀՊՖՆ',
      venue: _khachaturyanRu,
      venueAm: _khachaturyanAm,
      city: 'Ереван',
      lat: 40.1856, lng: 44.5136,
      date: DateTime(2026, 9, 19, 19, 0),
      category: EventCategory.concert,
      priceFrom: 6000,
      cover: const Color(0xFF0E3A5F),
      imageUrl: _imgPetrenko,
      description:
          'Дирижёр Василий Петренко и Армянский государственный '
          'филармонический оркестр — вечер большой симфонической музыки.',
      descriptionAm:
          'Դիրիժոր Վասիլի Պետրենկոն և Հայաստանի պետական ֆիլհարմոնիկ '
          'նվագախումբը՝ մեծ սիմֆոնիկ երաժշտության երեկո։',
      ticketTypes: const [
        TicketType(name: 'Балкон', nameAm: 'Բալկոն', price: 6000),
        TicketType(name: 'Партер', nameAm: 'Պարտեր', price: 12000),
        TicketType(name: 'Ложа', nameAm: 'Օթյակ', price: 22000),
      ],
    ),
    // 4. Кирилл Герштейн · Рахманинов.
    Event(
      id: 'e4',
      title: 'Кирилл Герштейн · Рахманинов',
      titleAm: 'Կիրիլ Գերշտեյն · Ռախմանինով',
      venue: _khachaturyanRu,
      venueAm: _khachaturyanAm,
      city: 'Ереван',
      lat: 40.1856, lng: 44.5136,
      date: DateTime(2026, 7, 4, 19, 0),
      category: EventCategory.concert,
      priceFrom: 7000,
      cover: const Color(0xFF3A2A1A),
      imageUrl: _imgGerstein,
      description:
          'Пианист Кирилл Герштейн исполняет Рахманинова — один из самых '
          'ярких фортепианных вечеров сезона.',
      descriptionAm:
          'Դաշնակահար Կիրիլ Գերշտեյնը կատարում է Ռախմանինով՝ սեզոնի '
          'ամենավառ դաշնամուրային երեկոներից մեկը։',
      ticketTypes: const [
        TicketType(name: 'Балкон', nameAm: 'Բալկոն', price: 7000),
        TicketType(name: 'Партер', nameAm: 'Պարտեր', price: 14000),
      ],
    ),
    // 5. Лебединое озеро — балет.
    Event(
      id: 'e5',
      title: 'Лебединое озеро',
      titleAm: 'Կարապի լիճ',
      venue: 'Театр оперы и балета им. Спендиаряна',
      venueAm: 'Սպենդիարյանի անվ. օպերայի և բալետի թատրոն',
      city: 'Ереван',
      lat: 40.1854, lng: 44.5139,
      date: DateTime(2026, 10, 15, 19, 0),
      category: EventCategory.theatre,
      priceFrom: 5000,
      cover: const Color(0xFF1F6FB2),
      refundGuarantee: true,
      refundUntilHours: 72,
      imageUrl: _imgOpera,
      description:
          'Классический балет Чайковского на сцене Национального театра '
          'оперы и балета. Вечер высокого искусства в сердце Еревана.',
      descriptionAm:
          'Չայկովսկու դասական բալետը Օպերայի և բալետի ազգային թատրոնի '
          'բեմում։ Բարձր արվեստի երեկո Երևանի սրտում։',
      ticketTypes: const [
        TicketType(name: 'Балкон', nameAm: 'Բալկոն', price: 5000),
        TicketType(name: 'Партер', nameAm: 'Պարտեր', price: 11000),
        TicketType(name: 'Ложа', nameAm: 'Օթյակ', price: 18000),
      ],
    ),
    // 6. Новогодний гала-концерт.
    Event(
      id: 'e6',
      title: 'Новогодний гала-концерт',
      titleAm: 'Ամանորյա գալա-համերգ',
      venue: _demirchyanRu,
      venueAm: _demirchyanAm,
      city: 'Ереван',
      lat: 40.1872, lng: 44.4856,
      date: DateTime(2026, 12, 27, 19, 0),
      category: EventCategory.festival,
      priceFrom: 10000,
      cover: const Color(0xFF6B1F3A),
      imageUrl: _imgDemirchyan,
      description:
          'Большой праздничный гала-концерт под Новый год в крупнейшей '
          'площадке страны — звёзды армянской и мировой сцены.',
      descriptionAm:
          'Մեծ տոնական գալա-համերգ Ամանորի առթիվ՝ երկրի ամենամեծ '
          'հարթակում, հայ և համաշխարհային բեմի աստղերով։',
      ticketTypes: const [
        TicketType(name: 'Стандарт', nameAm: 'Ստանդարտ', price: 10000),
        TicketType(name: 'VIP', nameAm: 'VIP', price: 30000, note: 'Столики у сцены'),
      ],
    ),
  ];
}
