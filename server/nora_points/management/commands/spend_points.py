from django.core.management.base import BaseCommand
from cinema.models import User, UserPointsBalance

MENU = {
    'напитки': {
        'вода 0.5л': 30,
        'кола 0.5л': 45,
        'фанта 0.5л': 45,
        'спрайт 0.5л': 45,
        'лимонад домашний': 50,
        'чай горячий': 25,
        'кофе эспрессо': 30,
        'капучино': 35,
    },
    'попкорн': {
        'маленький попкорн': 60,
        'средний попкорн': 90,
        'большой попкорн': 120,
        'попкорн с карамелью': 100,
        'попкорн с сыром': 110,
        'двойной попкорн (сладкий+солёный)': 130,
    },
    'закуски': {
        'чипсы солёные': 50,
        'чипсы крабовые': 55,
        'шоколадка': 45,
        'мармелад': 35,
        'печенье': 50,
        'батончик сникерс': 55,
        'батончик марс': 55,
        'сухарики': 40,
    },
    'комбо': {
        'комбо S (мал. попкорн + кола)': 95,
        'комбо M (ср. попкорн + кола + чипсы)': 140,
        'комбо L (бол. попкорн + 2 напитка + шоколадка)': 190,
        'детское комбо (мал. попкорн + вода + мармелад)': 80,
    }
}

class Command(BaseCommand):
    help = 'Симуляция траты баллов клиента в кинотеатре'

    def display_menu(self):
        self.stdout.write("\nМЕНЮ КИНОТЕАТРА")
        for category, items in MENU.items():
            self.stdout.write(f"\n{category.upper()}:")
            for item, cost in items.items():
                self.stdout.write(f"  • {item:<35} — {cost:>3} баллов")

    def get_all_items(self):
        all_items = {}
        for items in MENU.values():
            all_items.update(items)
        return all_items

    def handle(self, *args, **options):
        identifier = input("Введите email или телефон: ").strip()

        try:
            user = User.objects.get(email=identifier)
        except User.DoesNotExist:
            try:
                user = User.objects.get(phone=identifier)
            except User.DoesNotExist:
                self.stdout.write(self.style.ERROR("Пользователь не найден!"))
                return

        try:
            balance_obj = UserPointsBalance.objects.get(user=user)
        except UserPointsBalance.DoesNotExist:
            self.stdout.write(self.style.ERROR("У пользователя нет баланса баллов!"))
            return

        balance = balance_obj.current_points
        self.stdout.write(self.style.SUCCESS(f"Привет, {user.full_name}! Текущий баланс: {balance} баллов"))

        self.display_menu()
        all_items = self.get_all_items()

        while True:
            choice = input("\nЧто купить? (введите название или 'назад'): ").strip().lower()
            
            if choice == 'назад':
                self.stdout.write("До новых встреч кафе 'НОРА'!")
                break

            matched_items = [name for name in all_items.keys() if choice in name.lower()]
            
            if not matched_items:
                self.stdout.write(self.style.WARNING("⚠️ Такого товара нет. Попробуйте ещё раз."))
                continue

            if len(matched_items) > 1:
                self.stdout.write("Найдено несколько вариантов:")
                for i, item in enumerate(matched_items, 1):
                    self.stdout.write(f"  {i}. {item}")
                try:
                    sel = int(input("Выберите номер: ")) - 1
                    if 0 <= sel < len(matched_items):
                        selected_item = matched_items[sel]
                    else:
                        raise ValueError
                except (ValueError, IndexError):
                    self.stdout.write(self.style.ERROR("Неверный выбор"))
                    continue
            else:
                selected_item = matched_items[0]

            cost = all_items[selected_item]
            if balance < cost:
                self.stdout.write(self.style.ERROR(f"Недостаточно баллов! Необходимо {cost}, а у вас {balance}."))
                continue

            balance -= cost
            balance_obj.current_points = balance
            balance_obj.save(update_fields=['current_points'])
            self.stdout.write(self.style.SUCCESS(f"Покупка успешна! Куплено: {selected_item} за {cost} баллов. Остаток: {balance}"))