import SwiftUI

struct DeveloperStrategyDocView: View {
    @Environment(\.dismiss) private var dismiss
    
    private let docText = """
    # Руководство по форматированию статей "Стратегия"
    
    Компонент `RichCardText` автоматически находит в тексте покерные нотации и превращает их в красивые UI-компоненты (карты и комбо).
    
    ## 1. Карты борда (Флоп, Терн, Ривер)
    Для отображения нескольких карт подряд, используйте дефисы без пробелов. Это гарантирует, что они будут сгруппированы вместе:
    - **Флоп**: `Ah-Kd-2c` (Выведет три карты в ряд с небольшим отступом)
    - **Терн/Ривер**: `Jd` или `Ts` (Одиночные карты)
    - *Внимание:* Обязательно ставьте пробелы до и после группы (например, "Флоп: Ah-Kd-2c .").
    
    ## 2. Карманные карты (Стартовые руки)
    Две конкретные карты пишутся слитно (4 символа). Парсер автоматически разделит их и добавит правильный отступ:
    - `QdJd` -> Выведет две карты (Q♦ и J♦)
    - `AhKh`, `2c2s`
    
    ## 3. Комбинации диапазонов (Hand Combos)
    Комбо отображаются в виде двух перекрывающихся карт с цветовым бейджем масти.
    Цветовое кодирование карт: разномастные руки и пары выделяются красным цветом второй карты для визуального контраста.
    - **Пары**: `22`, `AA` (Две одинаковые карты)
    - **Пары с плюсом**: `22+` (Пара двоек и выше. Выводит бейдж '+')
    - **Одномастные (Suited)**: `K9s`, `K9s+` (Выводит лаймовый бейдж 's' или 's+')
    - **Разномастные (Offsuit)**: `A3o`, `A3o+` (Выводит персиковый бейдж 'o' или 'o+')
    - **Только ранги**: `AK` (Также парсится как базовое комбо)
    
    ## 4. Диапазоны комбо (Combo Ranges)
    Для указания диапазона "от и до" используйте дефис между двумя валидными комбо:
    - `A2o-A5o` -> Выведет две комбо-карточки, разделенные текстовым дефисом.
    - `22-77`, `K2s-K9s`
    
    ## 5. Важные правила парсинга и синтаксиса
    1. **Изоляция пробелами**: Старайтесь отделять нотации пробелами. Если знак препинания приклеен к нотации (например, `A3o+,`), парсер аккуратно отделит запятую. Однако для сложных конструкций всегда надежнее использовать пробел.
    2. **Регистр мастей**: Масти ДОЛЖНЫ быть строчными английскими буквами: 
       - `h` (hearts/черви)
       - `d` (diamonds/бубны)
       - `c` (clubs/трефы)
       - `s` (spades/пики)
    3. **Регистр рангов**: Ранги ДОЛЖНЫ быть заглавными английскими буквами или цифрами: `A`, `K`, `Q`, `J`, `T`, `9`-`2`. Не используйте `10`, используйте `T`.
    4. **Исключение процентов (%)**: Любое слово, содержащее символ `%` (например, `33%`, `100%`), будет полностью проигнорировано парсером. Это сделано специально, чтобы парсер не путал процентные ставки с карманными парами (например, пара 33). Пишите проценты слитно: `33%` вместо `33 %`.
    
    ## 6. Пример идеального текста для JSON/базы данных:
    "Вы открылись на баттоне, BB коллировал. Флоп: Kh-7d-2c . У вас QdJd (воздух). Вы ставите контбет 33% пота. Оппонент сбрасывает 9d8d . Базовый диапазон пуша: 22+ , A2s+ , A7o+ , KTs+ , A2o-A5o ."
    """

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        Text("Этот экран предназначен для редакторов статей. Здесь описаны правила, по которым текст превращается в покерные карточки.")
                            .font(AppTypography.subheadline)
                            .foregroundStyle(AppColors.textSecondary)
                            .padding(.bottom, AppSpacing.sm)
                        
                        Text(docText)
                            .font(.system(size: 15, design: .monospaced))
                            .foregroundStyle(AppColors.textPrimary)
                            .lineSpacing(4)
                            // Makes the text selectable in standard SwiftUI
                            .textSelection(.enabled)
                    }
                    .padding(AppSpacing.pageHorizontal)
                }
            }
            .navigationTitle("Документация")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Text("Закрыть")
                            .font(AppTypography.body)
                            .foregroundStyle(AppColors.primaryMint)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        UIPasteboard.general.string = docText
                        // Give tactile feedback
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                    }) {
                        Image(systemName: "doc.on.doc")
                            .foregroundStyle(AppColors.primaryMint)
                    }
                }
            }
        }
    }
}

#Preview {
    DeveloperStrategyDocView()
}
