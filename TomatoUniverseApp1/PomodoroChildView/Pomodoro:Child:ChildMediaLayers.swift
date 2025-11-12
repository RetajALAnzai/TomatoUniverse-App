import SwiftUI
import UIKit

// MARK: - ChildMedia: صورة فل-فت تحت + طبقة البندورة فوقها دائماً
enum ChildMedia {

    /// يبني الطبقات للمربع: صورة فل-فت (لو موجودة) ثم البندورة فوقها
    @ViewBuilder
    static func tomatoCell(
        photoData: Data?,
        iconName: String,
        tomatoColor: Color,
        cellHeight: CGFloat,
        tomatoScale: CGFloat = 1.0,   // كبّر/صغّر البندورة
        corner: CGFloat = 18,
        locked: Bool = false
    ) -> some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack {
                // --- الطبقة السفلية: صورة المستخدم فل-فت ---
                if let ui = uiImage(from: photoData) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFill()
                        .frame(width: w, height: cellHeight)
                        .clipped()
                        .zIndex(0)
                } else {
                    // خلفية بسيطة لو ما فيه صورة
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .frame(width: w, height: cellHeight)
                        .zIndex(0)
                }

                // --- الطبقة العلوية: البندورة دائماً فوق ---
                Image(iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: cellHeight * tomatoScale)
                    .colorMultiply(tomatoColor)
                    .opacity(locked ? 0.35 : 1.0)
                    .shadow(radius: 2, y: 1)
                    .zIndex(1)
            }
            .frame(width: w, height: cellHeight)
            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
            .contentShape(Rectangle())
        }
        .frame(height: cellHeight) // مهم: يثبت ارتفاع الخلية
    }

    private static func uiImage(from data: Data?) -> UIImage? {
        guard let data else { return nil }
        return UIImage(data: data)
    }
}
