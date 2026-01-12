from django.core.management.base import BaseCommand
from cinema.models import User, UserPointsBalance

MENU = {
    'вода': 20,
    'чай': 30,
    'кофе': 30,
    'попкорн': 50,
    'назад': None
}

class Command(BaseCommand):
    help = 'Симуляция траты баллов клиента (только для пользователей с балансом)'

    def handle(self, *args, **options):
        identifier = input("Введите email или телефон: ").strip()

        # Поиск пользователя
        try:
            user = User.objects.get(email=identifier)
        except User.DoesNotExist:
            try:
                user = User.objects.get(phone=identifier)
            except User.DoesNotExist:
                self.stdout.write(self.style.ERROR("Пользователь не найден."))
                return

        # Получение баланса (только если существует)
        try:
            balance_obj = UserPointsBalance.objects.get(user=user)
        except UserPointsBalance.DoesNotExist:
            self.stdout.write(self.style.ERROR("У пользователя нет баланса баллов."))
            return

        balance = balance_obj.current_points
        self.stdout.write(f"Текущий баланс: {balance}")

        self.stdout.write("\nМеню:")
        for item, cost in MENU.items():
            if cost:
                self.stdout.write(f"  {item} — {cost} баллов")

        while True:
            choice = input("\nЧто купить? (или 'назад'): ").strip().lower()
            if choice == 'назад':
                break
            if choice not in MENU or MENU[choice] is None:
                self.stdout.write(self.style.WARNING("Нет такого пункта."))
                continue

            cost = MENU[choice]
            if balance < cost:
                self.stdout.write(self.style.ERROR("Недостаточно баллов."))
                continue

            # Списание
            balance -= cost
            balance_obj.current_points = balance
            balance_obj.save(update_fields=['current_points'])
            self.stdout.write(self.style.SUCCESS(f"Куплено: {choice}. Остаток: {balance}"))