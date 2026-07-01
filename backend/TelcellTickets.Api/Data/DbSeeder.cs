using TelcellTickets.Api.Models;

namespace TelcellTickets.Api.Data;

/// <summary>Демо-данные: площадки Еревана с реальными координатами + события.</summary>
public static class DbSeeder
{
    public static void Seed(AppDbContext db)
    {
        if (db.Events.Any()) return;

        var stadium = new Venue
        {
            Id = Guid.NewGuid(), 
            Name = "Республиканский стадион", 
            NameAm = "Հանրապետական ստադիոն",
            City = "Yerevan",
            Address = "ул. Цицернакаберди", 
            AddressAm = "Ծիծեռնակաբերդի փողոց",
            Latitude = 40.1745, 
            Longitude = 44.4894
        };
        var opera = new Venue
        {
            Id = Guid.NewGuid(), 
            Name = "Театр оперы и балета", 
            NameAm = "Օպերայի և բալետի թատրոն",
            City = "Yerevan",
            Address = "пл. Свободы 54", 
            AddressAm = "Ազատության հրապարակ 54",
            Latitude = 40.1869, 
            Longitude = 44.5147
        };
        var saryan = new Venue
        {
            Id = Guid.NewGuid(), 
            Name = "Улица Сарьяна", 
            NameAm = "Սարյան փողոց",
            City = "Yerevan",
            Address = "ул. Сарьяна", 
            AddressAm = "Սարյան փողոց",
            Latitude = 40.1840, 
            Longitude = 44.5095
        };
        var karen = new Venue
        {
            Id = Guid.NewGuid(), 
            Name = "Концертный зал им. Демирчяна", 
            NameAm = "Դեմիրճյանի անվան համերգասրահ",
            City = "Yerevan",
            Address = "ул. Цицернакаберди 1", 
            AddressAm = "Ծիծեռնակաբերդի փողոց 1",
            Latitude = 40.1772, 
            Longitude = 44.4862
        };
        var meridian = new Venue
        {
            Id = Guid.NewGuid(), 
            Name = "Meridian Expo Center", 
            NameAm = "Meridian Expo Center",
            City = "Yerevan",
            Address = "ул. Дзорап 50", 
            AddressAm = "Ձորափի փողոց 50",
            Latitude = 40.1577, 
            Longitude = 44.4978
        };

        // Сначала сохраняем площадки
        db.Venues.AddRange(stadium, opera, saryan, karen, meridian);
        db.SaveChanges();

        Event Make(string title, string titleAm, string desc, string descAm, EventCategory cat, DateTimeOffset when,
            string color, Venue venue, bool featured, string? imageUrl, params (string name, string nameAm, decimal price, int qty)[] types)
        {
            var ev = new Event
            {
                Id = Guid.NewGuid(), 
                Title = title, 
                TitleAm = titleAm,
                Description = desc, 
                DescriptionAm = descAm,
                Category = cat,
                StartsAt = when, 
                CoverColorHex = color,
                CoverImageUrl = imageUrl,
                VenueId = venue.Id, 
                IsFeatured = featured
            };
            foreach (var (n, nAm, p, q) in types)
                ev.TicketTypes.Add(new TicketType
                {
                    Id = Guid.NewGuid(), 
                    Name = n, 
                    NameAm = nAm,
                    Price = p, 
                    Quantity = q, 
                    EventId = ev.Id
                });
            return ev;
        }

        var now = DateTimeOffset.UtcNow;
        
        // Добавляем события по одному, чтобы избежать разрыва соединения
        db.Events.Add(Make(
            "System of a Down · Yerevan",
            "System of a Down · Երևան",
            "Легендарная группа возвращается в Ереван с большим стадионным шоу.",
            "Լեգենդար խումբը վերադառնում է Երևան մեծ ստադիոնային շոուով։",
            EventCategory.Concert, new DateTimeOffset(now.AddDays(19).Date.AddHours(20), TimeSpan.Zero), "#7B2FF7", stadium, true,
            "https://upload.wikimedia.org/wikipedia/commons/thumb/7/7f/System_of_a_Down_live_in_Astana.jpg/1280px-System_of_a_Down_live_in_Astana.jpg",
            ("Фан-зона", "Ֆան-զոնա", 15000, 5000), 
            ("Трибуна", "Տրիբունա", 25000, 8000), 
            ("VIP", "VIP", 60000, 500)));
        db.SaveChanges();

        db.Events.Add(Make(
            "Лебединое озеро",
            "Կարապի լիճը",
            "Классический балет Чайковского в постановке Национального театра.",
            "Չայկովսկու դասական բալետը Ազգային թատրոնի բեմադրությամբ։",
            EventCategory.Theatre, new DateTimeOffset(now.AddDays(6).Date.AddHours(19), TimeSpan.Zero), "#1F6FB2", opera, false,
            "https://upload.wikimedia.org/wikipedia/commons/thumb/1/19/%C3%93pera%2C_Erev%C3%A1n%2C_Armenia%2C_2016-10-03%2C_DD_12.jpg/1280px-%C3%93pera%2C_Erev%C3%A1n%2C_Armenia%2C_2016-10-03%2C_DD_12.jpg",
            ("Балкон", "Պատշգամբ", 6000, 200), 
            ("Партер", "Պարտեր", 12000, 300)));
        db.SaveChanges();

        db.Events.Add(Make(
            "Yerevan Wine Days",
            "Yerevan Wine Days",
            "Главный винный фестиваль года: дегустации, музыка, гастрономия.",
            "Տարվա գլխավոր գինու փառատոն՝ համտեսում, երաժշտություն, գաստրոնոմիա։",
            EventCategory.Festival, new DateTimeOffset(now.AddDays(13).Date.AddHours(16), TimeSpan.Zero), "#B0203C", saryan, true,
            "https://upload.wikimedia.org/wikipedia/commons/thumb/0/0e/Wine_Bottles.jpg/1280px-Wine_Bottles.jpg",
            ("Вход", "Մուտք", 3000, 10000)));
        db.SaveChanges();

        db.Events.Add(Make(
            "Tech Summit Armenia 2026",
            "Tech Summit Armenia 2026",
            "Крупнейшая IT-конференция региона: спикеры, нетворкинг, стартапы.",
            "Տարածաշրջանի խոշորագույն IT-կոնֆերանսը՝ բանախոսներ, ցանցավորում, ստարտափներ։",
            EventCategory.Conference, new DateTimeOffset(now.AddDays(30).Date.AddHours(10), TimeSpan.Zero), "#0E7C7B", meridian, false,
            "https://upload.wikimedia.org/wikipedia/commons/thumb/e/e4/Conference_audience.jpg/1280px-Conference_audience.jpg",
            ("Standard", "Standard", 20000, 800), 
            ("Pro", "Pro", 45000, 200)));
        db.SaveChanges();

        db.Events.Add(Make(
            "Армянский симфонический оркестр",
            "Հայկական սիմֆոնիկ նվագախումբ",
            "Вечер классической музыки в зале Демирчяна.",
            "Դասական երաժշտության երեկո Դեմիրճյանի սրահում։",
            EventCategory.Concert, new DateTimeOffset(now.AddDays(9).Date.AddHours(19), TimeSpan.Zero), "#2E2A6B", karen, false,
            "https://upload.wikimedia.org/wikipedia/commons/thumb/5/5a/Karen_Demirchyan_Sports_and_Concerts_Complex_shot_from_air%2C_May_2019.jpg/1280px-Karen_Demirchyan_Sports_and_Concerts_Complex_shot_from_air%2C_May_2019.jpg",
            ("Категория B", "Կատեգորիա B", 8000, 400), 
            ("Категория A", "Կատեգորիա A", 15000, 300)));
        db.SaveChanges();

        db.Events.Add(Make(
            "Modern Art Expo",
            "Modern Art Expo",
            "Выставка современного искусства армянских и зарубежных авторов.",
            "Հայ և օտարերկրյա հեղինակների ժամանակակից արվեստի ցուցահանդես։",
            EventCategory.Exhibition, new DateTimeOffset(now.AddDays(3).Date.AddHours(11), TimeSpan.Zero), "#5A4A8A", meridian, false,
            "https://upload.wikimedia.org/wikipedia/commons/thumb/3/32/Art_exhibition.jpg/1280px-Art_exhibition.jpg",
            ("Билет", "Տոմս", 4000, 2000)));
        db.SaveChanges();

        db.Events.Add(Make(
            "KALEO в Ереване",
            "KALEO Երևանում",
            "Исландская рок-группа KALEO впервые в Ереване с хитами Way Down We Go и No Good.",
            "Իսլանդական KALEO ռոք խումբը առաջին անգամ Երևանում Way Down We Go և No Good հիթերով։",
            EventCategory.Concert, new DateTimeOffset(now.AddDays(25).Date.AddHours(20), TimeSpan.Zero), "#1C1C24", karen, true,
            "https://upload.wikimedia.org/wikipedia/commons/f/f5/20180603_N%C3%BCrnberg_Rock_im_Park_Kaleo_0212.jpg",
            ("Фан-зона", "Ֆան-զոնա", 8000, 3000), 
            ("Танцпол", "Պարահրապարակ", 14000, 1500),
            ("VIP", "VIP", 28000, 200)));
        db.SaveChanges();

        db.Events.Add(Make(
            "Валерий Меладзе",
            "Վալերի Մելադզե",
            "Большой сольный концерт Валерия Меладзе — все главные хиты за тридцать лет.",
            "Վալերի Մելադզեի մեծ միակողմանի համերգը՝ երեսուն տարվա բոլոր հիթերը։",
            EventCategory.Concert, new DateTimeOffset(now.AddDays(40).Date.AddHours(20), TimeSpan.Zero), "#2A1A4A", stadium, false,
            "https://upload.wikimedia.org/wikipedia/commons/e/e1/Valeriy_Meladze_photoshooting_at_Laima_Rendez_Vous_Jurmala_2017.jpg",
            ("Балкон", "Պատշգամբ", 12000, 1000),
            ("Партер", "Պարտեր", 22000, 2000),
            ("VIP", "VIP", 45000, 300)));
        db.SaveChanges();

        db.Events.Add(Make(
            "Новогодний гала-концерт",
            "Նորոգանյա գալա համերգ",
            "Большой праздничный гала-концерт под Новый год — звёзды армянской и мировой сцены.",
            "Մեծ տոնական գալա համերգ Նոր տարվա առթիվ՝ հայ և համաշխարհային բեմի աստղերով։",
            EventCategory.Festival, new DateTimeOffset(now.AddDays(180).Date.AddHours(19), TimeSpan.Zero), "#6B1F3A", stadium, true,
            "https://upload.wikimedia.org/wikipedia/commons/thumb/b/b4/New_Year%27s_Eve_fireworks.jpg/1280px-New_Year%27s_Eve_fireworks.jpg",
            ("Стандарт", "Ստանդարտ", 10000, 5000),
            ("VIP", "VIP", 30000, 500)));
        db.SaveChanges();

        db.Events.Add(Make(
            "Иван Дорн",
            "Իվան Դորն",
            "Концерт украинского певца и продюсера Ивана Дорна с программой лучших хитов.",
            "Ուկրաինացի երգչի և պրոդյուսերի Իվան Դորնի համերգը լավագույն հիթերի ծրագրով։",
            EventCategory.Concert, new DateTimeOffset(now.AddDays(35).Date.AddHours(21), TimeSpan.Zero), "#FF6B9D", karen, true,
            "https://upload.wikimedia.org/wikipedia/commons/thumb/4/4c/Ivan_Dorn_2017.jpg/1280px-Ivan_Dorn_2017.jpg",
            ("Фан-зона", "Ֆան-զոնա", 7000, 2500), 
            ("Партер", "Պարտեր", 12000, 1800),
            ("VIP", "VIP", 25000, 300)));
        db.SaveChanges();

        db.Events.Add(Make(
            "Ромео и Джульетта",
            "Ռոմեո և Ջուլիետա",
            "Бессмертная трагедия Шекспира в современной постановке Национального театра.",
            "Շեքսպիրի անմահ ողբերգությունը Ազգային թատրոնի ժամանակակից բեմադրությամբ։",
            EventCategory.Theatre, new DateTimeOffset(now.AddDays(12).Date.AddHours(19), TimeSpan.Zero), "#8B1538", opera, false,
            "https://upload.wikimedia.org/wikipedia/commons/thumb/5/5f/Romeo_and_Juliet_tomb.jpg/1280px-Romeo_and_Juliet_tomb.jpg",
            ("Балкон", "Պատշգամբ", 5000, 250), 
            ("Партер", "Պարտեր", 9000, 350),
            ("Ложа", "Ապարանք", 18000, 50)));
        db.SaveChanges();

        db.Events.Add(Make(
            "Dua Lipa World Tour",
            "Dua Lipa World Tour",
            "Мировая поп-звезда Dua Lipa впервые в Ереване! Грандиозное шоу с хитами Levitating, Don't Start Now.",
            "Համաշխարհային փոփ աստղ Dua Lipa-ն առաջին անգամ Երևանում։ Վեհափառ շոու Levitating, Don't Start Now հիթերով։",
            EventCategory.Concert, new DateTimeOffset(now.AddDays(50).Date.AddHours(20), TimeSpan.Zero), "#EF4444", stadium, true,
            "https://upload.wikimedia.org/wikipedia/commons/thumb/7/7e/Dua_Lipa_in_2018.jpg/1280px-Dua_Lipa_in_2018.jpg",
            ("Фан-зона", "Ֆան-զոնա", 18000, 6000), 
            ("Трибуна", "Տրիբունա", 30000, 10000), 
            ("Golden Circle", "Golden Circle", 50000, 800),
            ("VIP", "VIP", 85000, 400)));
        db.SaveChanges();

        db.Events.Add(Make(
            "Stand-Up: Александр Незлобин",
            "Stand-Up: Ալեքսանդր Նեզլոբին",
            "Большой сольный концерт популярного стендап-комика Александра Незлобина.",
            "Հայտնի սթենդափ կոմիկոս Ալեքսանդր Նեզլոբինի մեծ միակողմանի համերգը։",
            EventCategory.Theatre, new DateTimeOffset(now.AddDays(22).Date.AddHours(20), TimeSpan.Zero), "#F59E0B", karen, false,
            "https://upload.wikimedia.org/wikipedia/commons/thumb/9/91/Stand-up_comedy_microphone.jpg/1280px-Stand-up_comedy_microphone.jpg",
            ("Партер", "Պարտեր", 8000, 1200),
            ("VIP", "VIP", 15000, 400)));
        db.SaveChanges();

        db.Events.Add(Make(
            "Jazz Night: Tigran Hamasyan",
            "Jazz Night: Տիգրան Համասյան",
            "Всемирно известный армянский джазовый пианист Тигран Амасян с новой программой.",
            "Համաշխարհային հռչակ ունեցող հայ ջազ դաշնակահար Տիգրան Համասյանը նոր ծրագրով։",
            EventCategory.Concert, new DateTimeOffset(now.AddDays(28).Date.AddHours(20), TimeSpan.Zero), "#1E3A8A", opera, true,
            "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Tigran_Hamasyan.jpg/1280px-Tigran_Hamasyan.jpg",
            ("Балкон", "Պատշգամբ", 10000, 300), 
            ("Партер", "Պարտեր", 18000, 400),
            ("VIP", "VIP", 35000, 100)));
        db.SaveChanges();

        db.Events.Add(Make(
            "Yerevan Street Food Festival",
            "Երևանի փողոցային կերակրի փառատոն",
            "Крупнейший гастрономический фестиваль Еревана: уличная еда, мастер-классы, музыка.",
            "Երևանի խոշորագույն գաստրոնոմիական փառատոնը՝ փողոցային կերակուր, վարպետաց դասեր, երաժշտություն։",
            EventCategory.Festival, new DateTimeOffset(now.AddDays(8).Date.AddHours(12), TimeSpan.Zero), "#DC2626", saryan, false,
            "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6d/Street_food_market.jpg/1280px-Street_food_market.jpg",
            ("Входной билет", "Մուտքի տոմս", 2000, 15000)));
        db.SaveChanges();

        db.Events.Add(Make(
            "Blockchain & AI Summit 2026",
            "Blockchain & AI Summit 2026",
            "Международная конференция по блокчейну и искусственному интеллекту. Топовые спикеры из США, Европы и Азии.",
            "Բլոկչեյնի և արհեստական ​​բանականության միջազգային կոնֆերանս։ Լավագույն բանախոսներ ԱՄՆ-ից, Եվրոպայից և Ասիայից։",
            EventCategory.Conference, new DateTimeOffset(now.AddDays(45).Date.AddHours(9), TimeSpan.Zero), "#8B5CF6", meridian, false,
            "https://upload.wikimedia.org/wikipedia/commons/thumb/4/46/Bitcoin.svg/1280px-Bitcoin.svg.png",
            ("Early Bird", "Early Bird", 15000, 500), 
            ("Standard", "Standard", 25000, 1000),
            ("VIP + Networking", "VIP + Networking", 60000, 150)));
        db.SaveChanges();

        db.Events.Add(Make(
            "Щелкунчик",
            "Ընկուզկոտրիչը",
            "Рождественская классика — балет Чайковского «Щелкунчик» в исполнении Национального балета.",
            "Սուրբ Ծննդյան դասական բալետ՝ Չայկովսկու «Ընկուզկոտրիչը» Ազգային բալետի կատարմամբ։",
            EventCategory.Theatre, new DateTimeOffset(now.AddDays(165).Date.AddHours(18), TimeSpan.Zero), "#047857", opera, true,
            "https://upload.wikimedia.org/wikipedia/commons/thumb/1/19/Nutcracker_ballet.jpg/1280px-Nutcracker_ballet.jpg",
            ("Балкон", "Պատշգամբ", 7000, 250), 
            ("Партер", "Պարտեր", 14000, 350),
            ("VIP", "VIP", 28000, 100)));
        db.SaveChanges();

        db.Events.Add(Make(
            "Red Hot Chili Peppers",
            "Red Hot Chili Peppers",
            "Легендарная рок-группа Red Hot Chili Peppers в Ереване! Хиты Californication, Under the Bridge и новый альбом.",
            "Լեգենդար Red Hot Chili Peppers ռոք խումբը Երևանում։ Californication, Under the Bridge հիթերը և նոր ալբոմը։",
            EventCategory.Concert, new DateTimeOffset(now.AddDays(60).Date.AddHours(20), TimeSpan.Zero), "#DC2626", stadium, true,
            "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c6/Red_Hot_Chili_Peppers_2016.jpg/1280px-Red_Hot_Chili_Peppers_2016.jpg",
            ("Фан-зона", "Ֆան-զոնա", 20000, 8000), 
            ("Трибуна", "Տրիբունա", 35000, 12000), 
            ("Golden Circle", "Golden Circle", 60000, 1000),
            ("VIP", "VIP", 95000, 500)));
        db.SaveChanges();

        db.Events.Add(Make(
            "Фотовыставка «Армения сквозь века»",
            "Լուսանկարչական ցուցահանդես «Հայաստանը դարերի միջով»",
            "Уникальная выставка исторических и современных фотографий Армении от ведущих фотохудожников.",
            "Հայաստանի պատմական և ժամանակակից լուսանկարների եզակի ցուցահանդես առաջատար լուսանկարիչների կողմից։",
            EventCategory.Exhibition, new DateTimeOffset(now.AddDays(5).Date.AddHours(10), TimeSpan.Zero), "#6366F1", meridian, false,
            "https://upload.wikimedia.org/wikipedia/commons/thumb/e/e5/Photography_exhibition.jpg/1280px-Photography_exhibition.jpg",
            ("Билет", "Տոմս", 3000, 3000)));
        db.SaveChanges();

        db.Events.Add(Make(
            "Halloween Horror Night",
            "Halloween Horror Night",
            "Грандиозная хэллоуинская вечеринка с лучшими диджеями Армении, костюмированное шоу и призы.",
            "Վեհափառ Halloween երեկույթ Հայաստանի լավագույն DJ-ների, կոստյումների շոուի և մրցանակների հետ։",
            EventCategory.Festival, new DateTimeOffset(now.AddDays(120).Date.AddHours(21), TimeSpan.Zero), "#FB923C", karen, true,
            "https://upload.wikimedia.org/wikipedia/commons/thumb/5/57/Halloween_pumpkins.jpg/1280px-Halloween_pumpkins.jpg",
            ("Обычный", "Սովորական", 6000, 2000),
            ("VIP + бар", "VIP + բար", 15000, 500)));
        db.SaveChanges();
    }
}
