import 'package:flutter/material.dart';

/// Поддерживаемые языки приложения: русский и армянский.
enum AppLanguage { ru, am }

extension AppLanguageX on AppLanguage {
  /// Язык, на который переключит кнопка (а не текущий).
  /// Сейчас RU → показываем «ՀԱՅ» (переключит на армянский).
  String get toggleLabel => this == AppLanguage.ru ? 'ՀԱՅ' : 'РУС';

  /// Подпись текущего языка (для индикаторов, где нужен именно текущий).
  String get code => this == AppLanguage.ru ? 'РУС' : 'ՀԱՅ';
}

/// Словарь строк (без сторонних пакетов).
/// При подключении intl/arb — заменить сгенерированным.
class AppStrings {
  final AppLanguage lang;
  const AppStrings(this.lang);

  /// Выбор перевода: [ru] — русский, [am] — армянский.
  String _t(String ru, String am) => lang == AppLanguage.ru ? ru : am;

  // ── Onboarding ──────────────────────────────────────────────────────────
  String get brandName => 'Telcell Tickets';
  String get brandTagline => _t('СОБЫТИЯ В АРМЕНИИ', 'ՄԻՋՈՑԱՌՈՒՄՆԵՐ ՀԱՅԱՍՏԱՆՈՒՄ');
  String get onboardHeadline =>
      _t('Твой вечер\nначинается здесь.', 'Քո երեկոն\nսկսվում է այստեղ։');
  String get onboardBody => _t(
      'Концерты, театр, фестивали и события по всей Армении — билеты в один тап через Telcell Wallet.',
      'Համերգներ, թատրոն, փառատոներ և միջոցառումներ ողջ Հայաստանում — տոմսեր մեկ հպումով Telcell Wallet-ով։');
  String get continueWallet =>
      _t('Войти через Telcell Wallet', 'Մուտք Telcell Wallet-ով');
  String get continueGuest => _t('Продолжить как гость', 'Շարունակել որպես հյուր');
  String get legal => _t(
      'Продолжая, вы принимаете условия и политику Telcell Tickets.',
      'Շարունակելով՝ դուք ընդունում եք Telcell Tickets-ի պայմաններն ու քաղաքականությունը։');

  // ── Вход по телефону + OTP (Задача 2) ─────────────────────────
  String get loginTitle      => _t('Вход в аккаунт', 'Մուտք հաշիվ');
  String get loginPhoneStep  => _t(
      'Введите номер телефона — пришлём код подтверждения.',
      'Մուտքագրեք հեռախոսահամարը՝ կուղարկենք հաստատման կոդը։');
  String get loginCodeStep   => _t(
      'Введите код из SMS.',
      'Մուտքագրեք SMS-ից ստացած կոդը։');
  String get nameHint        => _t('Имя (необязательно)', 'Անուն (ոչ պարտադիր)');
  String get loginPhoneHint  => _t('Номер телефона', 'Հեռախոսահամար');
  String get codeHint        => _t('Код из SMS', 'SMS կոդ');
  String get sendCode        => _t('Получить код', 'Առաքել կոդ');
  String get confirmCode     => _t('Подтвердить', 'Հաստատել');
  String get changePhone     => _t('Изменить номер', 'Փոխել համարը');
  String get resendCode      => _t('Отправить код заново', 'Ուղարկել կոդը կրկին');
  String devCodeHint(String c) => _t(
      'Dev-режим: код $c',
      'Dev-ռեժիմ՝ կոդ $c');
  String get loginFailed     => _t('Не удалось войти', 'Չհաջողվեց մուտք գործել');
  String get loginCta        => _t('Войти', 'Մուտք');
  String get signOut         => _t('Выйти', 'Դուրս գալ');
  String get guestBadge      => _t('Гостевой режим', 'Հյուրի ռեժիմ');

  // ── Onboarding-фичи ───────────────────────────────────────────────────────
  String get featureOneTap => _t('1 клик', '1 հպում');
  String get featureQr     => _t('QR-билет', 'QR-տոմս');
  String get featureSafe   => _t('Защита', 'Պաշտպանություն');

  // ── Navigation ──────────────────────────────────────────────────────────
  String get navHome    => _t('Главная', 'Գլխավոր');
  String get navSearch  => _t('Поиск', 'Որոնում');
  String get navMap     => _t('Карта', 'Քարտեզ');
  String get navTickets => _t('Билеты', 'Տոմսեր');
  String get navProfile => _t('Профиль', 'Պրոֆիլ');

  // ── Catalog ─────────────────────────────────────────────────────────────
  String get greeting    => _t('Привет 👋', 'Բարև 👋');
  String get city        => _t('Ереван', 'Երևան');
  String get guest       => _t('Гость', 'Հյուր');
  String get searchHint  => _t('Поиск событий, артистов, мест…', 'Միջոցառումների, արտիստների, վայրերի որոնում…');
  String get featuredBadge => _t('Рекомендуем', 'Առաջարկվող');
  String get categoriesTitle => _t('Категории', 'Կատեգորիաներ');
  String get upcoming    => _t('Ближайшие события', 'Մոտակա միջոցառումները');
  String get seeAll      => _t('посмотреть все', 'տեսնել բոլորը');
  String get emptyTitle  => _t('Ничего не нашлось', 'Ոչինչ չգտնվեց');
  String get emptyBody   => _t('Попробуйте другой запрос или категорию.', 'Փորձեք այլ հարցում կամ կատեգորիա։');
  String get notFound    => _t('Событий не нашлось', 'Միջոցառումներ չգտնվեցին');
  String get sectionInProgress => _t('Раздел в разработке', 'Բաժինը մշակման փուլում է');

  // ── Event details ────────────────────────────────────────────────────────
  String get aboutEvent  => _t('Описание', 'Նկարագրություն');
  String get tickets     => _t('Типы билетов', 'Տոմսերի տեսակները');
  String get priceFrom   => _t('От', 'Սկսած');
  String get buyTicket   => _t('Купить билет', 'Գնել տոմս');
  String get buyShort    => _t('Купить', 'Գնել');

  // ── Checkout ─────────────────────────────────────────────────────────────
  String get checkout        => _t('Оформление', 'Ձևակերպում');
  String get selectTickets   => _t('Выберите билеты', 'Ընտրեք տոմսերը');
  String get selectTicketsHint => _t(
      'Выберите тип билета и количество, затем перейдите к оплате.',
      'Ընտրեք տոմսի տեսակն ու քանակը, ապա անցեք վճարման։');
  String get proceedToPay    => _t('К оплате', 'Վճարման անցնել');
  String get yourOrder       => _t('Ваш заказ', 'Ձեր պատվերը');

  // Контакт покупателя (Guest Checkout, PRD §11.2)
  String get contactTitle    => _t('Контакт для билета', 'Կոնտակտ տոմսի համար');
  String get contactNote     => _t(
      'Билет придёт на email. Регистрация не требуется.',
      'Տոմսը կուղարկվի email-ին։ Գրանցում չի պահանջվում։');
  String get emailHint       => _t('Email', 'Email');
  String get phoneHint       => _t('Телефон', 'Հեռախոս');
  String get contactWallet   => _t(
      'Данные из Telcell Wallet', 'Տվյալները Telcell Wallet-ից');
  String get errEmail        => _t('Введите корректный email', 'Մուտքագրեք վավեր email');
  String get errPhone        => _t('Введите телефон', 'Մուտքագրեք հեռախոսը');

  // Стоимость (PRD §9.3 — полная стоимость до оплаты)
  String get subtotal        => _t('Билеты', 'Տոմսեր');
  String get bookingFee      => _t('Сервисный сбор', 'Սպասարկման վճար');

  // Политика возврата (PRD §8, Сценарий В)
  String get refundTitle     => _t('Возврат', 'Վերադարձ');
  String get refundYes       => _t('Возврат доступен', 'Վերադարձը հասանելի է');
  String get refundNo        => _t('Билеты невозвратны', 'Տոմսերը վերադարձման ենթակա չեն');
  String refundYesBody(int h) => _t(
      'Можно вернуть не позднее чем за $h ч до начала события.',
      'Կարող եք վերադարձնել ոչ ուշ քան $h ժ միջոցառման մեկնարկից առաջ։');
  String get refundNoBody    => _t(
      'После оплаты возврат недоступен. Билет можно передать другому человеку.',
      'Վճարումից հետո վերադարձ չկա։ Տոմսը կարող եք փոխանցել այլ անձի։');

  String get promoCode       => _t('Промокод', 'Պրոմոկոդ');
  String get promoHint       => _t('Введите промокод', 'Մուտքագրեք պրոմոկոդը');
  String get paymentMethod   => _t('Способ оплаты', 'Վճարման եղանակ');
  String get payWallet       => 'Telcell Wallet';
  String get payWalletSub    => _t('Оплата в один тап', 'Վճարում մեկ հպումով');
  String get payCard         => _t('Банковская карта', 'Բանկային քարտ');
  String get payCardSub      => 'Visa · Mastercard · ArCa';
  String get total           => _t('Итого', 'Ընդամենը');
  String get confirmPay      => _t('Подтвердить и оплатить', 'Հաստատել և վճարել');
  String get paySuccess      => _t('🎉 Билеты у вас!', '🎉 Տոմսերը ձերն են։');
  String get ticketsBought   => _t('билет(а) добавлено в Мои билеты.', 'տոմս ավելացվեց «Իմ տոմսերում»։');
  String get goToTickets     => _t('Открыть мои билеты', 'Բացել իմ տոմսերը');
  String get backToCatalog   => _t('Вернуться в каталог', 'Վերադառնալ կատալոգ');

  // ── My Tickets ───────────────────────────────────────────────────────────
  String get myTicketsSub  => _t('Ваши покупки всегда под рукой.', 'Ձեր գնումները միշտ ձեռքի տակ։');
  String get tabMyQr       => _t('Мой QR-код', 'Իմ QR-կոդը');
  String get tabScan       => _t('Сканировать код', 'Սկանավորել կոդը');
  String get statusActive  => _t('Активен', 'Ակտիվ');
  String get statusUsed    => _t('Использован', 'Օգտագործված');
  String get statusTransferred => _t('Передан', 'Փոխանցված');
  String get statusRefunded => _t('Возвращён', 'Վերադարձված');
  String get statusCancelled => _t('Аннулирован', 'Չեղարկված');
  String get qrCaption     => _t('Ваш QR-билет', 'Ձեր QR-տոմսը');

  // Передача билета (PRD §5.5, US-03)
  String get transfer        => _t('Передать', 'Փոխանցել');
  String get transferTitle   => _t('Передать билет', 'Փոխանցել տոմսը');
  String get transferBody    => _t(
      'Введите email или телефон получателя. Ваш QR будет аннулирован, '
      'билет получит новый владелец.',
      'Մուտքագրեք ստացողի email-ը կամ հեռախոսը։ Ձեր QR-ը կչեղարկվի, '
      'տոմսը կստանա նոր սեփականատերը։');
  String get transferHint    => _t('Email или телефон', 'Email կամ հեռախոս');
  String get transferConfirm => _t('Передать билет', 'Փոխանցել տոմսը');
  String get transferDone    => _t('Билет передан', 'Տոմսը փոխանցված է');
  String get transferFailed  => _t('Не удалось передать билет', 'Չհաջողվեց փոխանցել տոմսը');

  // Моментальный поиск получателя (Задача 1, баг передачи)
  String get transferSearching => _t('Ищем получателя…', 'Փնտրում ենք ստացողին…');
  String transferFound(String name) => _t('Получатель: $name', 'Ստացող՝ $name');
  String get transferNotFound => _t(
      'Пользователь не найден. Проверьте телефон или email.',
      'Օգտատերը չի գտնվել։ Անհրաժեշտ է ստուգել հեռախոսը կամ email-ը։');
  String get transferEnterContact => _t(
      'Введите телефон или email получателя.',
      'Մուտքագրեք ստացողի հեռախոսը կամ email-ը։');
  String transferredTo(String c) => _t('Передан: $c', 'Փոխանցված է՝ $c');
  String get qrVoided        => _t('QR аннулирован', 'QR-ը չեղարկված է');

  // ── Сценарии отмены / переноса события (PRD §8, Сценарии А и Б) ───────────
  // Статус-бейджи
  String get statusEventCancelled => _t('Событие отменено', 'Միջոցառումը չեղարկված է');
  String get statusRescheduled    => _t('Перенесено', 'Տեղափոխված է');

  // Баннер отмены (Сценарий А)
  String get cancelBannerTitle => _t('Событие отменено', 'Միջոցառումը չեղարկվեց');
  String cancelBannerBody(int days) => _t(
      'Организатор отменил мероприятие. Деньги вернутся в полном объёме '
      'в течение $days раб. дней.',
      'Կազմակերպիչը չեղարկել է միջոցառումը։ Գումարն ամբողջությամբ կվերադարձվի '
      '$days աշխատանքային օրվա ընթացքում։');

  // Баннер переноса — ожидание решения 72ч (Сценарий Б)
  String get rescheduleBannerTitle => _t('Дата изменена', 'Ամսաթիվը փոխվեց');
  String rescheduleBannerBody(String date) => _t(
      'Новая дата: $date. Подтвердите участие или запросите возврат.',
      'Նոր ամսաթիվ՝ $date։ Հաստատեք մասնակցությունը կամ պահանջեք վերադարձ։');
  String get rescheduleBannerBodyNoDate => _t(
      'Организатор переносит мероприятие. Подтвердите участие или запросите возврат.',
      'Կազմակերպիչը տեղափոխում է միջոցառումը։ Հաստատեք մասնակցությունը կամ պահանջեք վերադարձ։');
  String get rescheduleOptOut => _t(
      'Если не ответить в течение 72 часов, билет останется действительным на новую дату.',
      'Եթե 72 ժամվա ընթացքում չպատասխանեք, տոմսը կմնա վավեր նոր ամսաթվի համար։');
  String get requestRefund     => _t('Запросить возврат', 'Պահանջել վերադարձ');
  String get confirmAttendance => _t('Подтвердить участие', 'Հաստատել մասնակցությունը');

  // Баннер подтверждённого переноса
  String get rescheduleConfirmedTitle => _t('Участие подтверждено', 'Մասնակցությունը հաստատվեց');
  String rescheduleConfirmedBody(String date) => _t(
      'Ваш билет действителен на новую дату: $date.',
      'Ձեր տոմսը վավեր է նոր ամսաթվի համար՝ $date։');

  // Снэкбары и диалог возврата (экран «Мои билеты»)
  String get rescheduleConfirmed => _t('Участие подтверждено', 'Մասնակցությունը հաստատվեց');
  String get refundDialogTitle   => _t('Запросить возврат?', 'Պահանջե՞լ վերադարձ');
  String get refundDialogBody    => _t(
      'Билет будет аннулирован, деньги вернутся в течение 5 рабочих дней.',
      'Տոմսը կչեղարկվի, գումարը կվերադարձվի 5 աշխատանքային օրվա ընթացքում։');
  String get refundDialogConfirm => _t('Запросить возврат', 'Պահանջել վերադարձ');
  String get refundRequested     => _t('Возврат запрошен', 'Վերադարձը պահանջվեց');

  String get scanHint      => _t(
      'Помести QR-код в центр квадрата.\nСканирование произойдёт автоматически',
      'Տեղադրեք QR-կոդը քառակուսու կենտրոնում։\nՍկանավորումը կկատարվի ինքնաշխատ');
  String get enterId       => _t('Ввести ID', 'Մուտքագրել ID');
  String get openGallery   => _t('Открыть из галереи', 'Բացել պատկերասրահից');
  String get noTicketsTitle => _t('Билетов пока нет', 'Տոմսեր դեռ չկան');
  String get noTicketsBody  => _t(
      'Найдите любимое событие и купите билеты в несколько тапов.',
      'Գտեք ձեր սիրելի միջոցառումը և գնեք տոմսեր մի քանի հպումով։');

  // ── Categories ───────────────────────────────────────────────────────────
  // ─── Push-уведомления (Задача 3) ──────────────────────────────────────
  String get pushBuyTitle => _t('Покупка оформлена', 'Գնումը կատարված է');
  String pushBuyBody(String eventTitle, int count) => _t(
        '$count билет(ов) на «$eventTitle» уже в разделе «Мои билеты».',
        '«$eventTitle» միջոցառման $count տոմս արդեն «Իմ տոմսերը» բաժնում է։',
      );
  String get pushCancelTitle => _t('Событие отменено', 'Միջոցառումը չեղարկվել է');
  String pushCancelBody(String eventTitle) => _t(
        '«$eventTitle» отменено организатором. Возврат средств выполняется автоматически.',
        '«$eventTitle»-ը չեղարկվել է կազմակերպչի կողմից։ Գումարը կվերադարձվի ավտոմատ կերպով։',
      );
  String get pushRescheduleTitle =>
      _t('Дата события изменена', 'Միջոցառման ամսաթիվը փոխվել է');
  String pushRescheduleBody(String eventTitle) => _t(
        '«$eventTitle» перенесено. Откройте «Мои билеты», чтобы подтвердить участие или запросить возврат.',
        '«$eventTitle»-ը տեղափոխվել է։ Բացեք «Իմ տոմսերը»՝ մասնակցությունը հաստատելու կամ գումարը վերադարձնելու համար։',
      );

  String category(String key) {
    switch (key) {
      case 'all':        return _t('Все', 'Բոլորը');
      case 'concert':    return _t('Концерты', 'Համերգներ');
      case 'theatre':    return _t('Театр', 'Թատրոն');
      case 'festival':   return _t('Фестивали', 'Փառատոներ');
      case 'conference': return _t('Конференции', 'Կոնֆերանսներ');
      case 'exhibition': return _t('Выставки', 'Ցուցահանդեսներ');
    }
    return key;
  }
}

/// Лёгкий InheritedWidget для языка и строк из любого места.
class AppLocale extends InheritedWidget {
  final AppLanguage language;
  final VoidCallback toggle;

  const AppLocale({
    super.key,
    required this.language,
    required this.toggle,
    required super.child,
  });

  AppStrings get strings => AppStrings(language);

  static AppLocale of(BuildContext context) {
    final w = context.dependOnInheritedWidgetOfExactType<AppLocale>();
    assert(w != null, 'AppLocale not found in widget tree');
    return w!;
  }

  static AppStrings stringsOf(BuildContext context) => of(context).strings;

  @override
  bool updateShouldNotify(AppLocale oldWidget) =>
      oldWidget.language != language;
}
