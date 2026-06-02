import SwiftUI

struct DeveloperStrategyDocView: View {
    @Environment(\.dismiss) private var dismiss
    
    private let docText = """
    # Руководство по форматированию статей "Стратегия"
    
    Компонент `RichCardText` автоматически находит в тексте покерные нотации и превращает их в красивые UI-компоненты.
    
    ## 1. Карты борда (Флоп, Терн, Ривер)
    Используйте дефисы без пробелов для объединения карт:
    - **Флоп**: `Ah-Kd-2c`
    - **Терн**: `Jd`
    - **Ривер**: `Ts`
    - *Внимание:* Ставьте пробелы до и после группы (например, "Флоп: Ah-Kd-2c .").
    
    ## 2. Карманные карты (Стартовые руки)
    Пишите две карты подряд без пробелов:
    - `QdJd`, `AhKh`, `2c2s`
    
    ## 3. Комбинации диапазонов (Hand Combos)
    Комбо автоматически стилизуются. Одномастные — зеленый `s`, разномастные — красный `o`, пары — зеленый значок `+`.
    - **Пары**: `22`, `22+`
    - **Одномастные**: `K9s`, `K9s+`
    - **Разномастные**: `A3o`, `A3o+`
    
    ## 4. Диапазоны (Ranges)
    Используйте дефис между двумя комбо:
    - `A2o-A5o` (превратится в карточки A2o - A5o)
    - `K2s-K9s`
    
    ## 5. Важные правила парсинга
    1. **Изоляция**: Старайтесь отделять нотации пробелами. Если знак препинания приклеен к нотации (например, `A3o+,`), парсер отделит запятую автоматически, но для сложных конструкций лучше использовать пробел.
    2. **Масти**: Используйте маленькие английские буквы для мастей: `h` (черви), `d` (бубны), `c` (трефы), `s` (пики).
    3. **Проценты**: Числа с процентами (например, `33%`) игнорируются парсером и выводятся как текст. Не пишите `33 %`, пишите слитно `33%`.
    4. **Заглавные**: Ранги карт должны быть заглавными английскими буквами: `A`, `K`, `Q`, `J`, `T`.
    
    ## 6. Пример идеального текста:
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
