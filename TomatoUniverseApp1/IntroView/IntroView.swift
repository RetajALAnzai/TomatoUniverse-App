import SwiftUI

// MARK: - Transparent card (نفس ستايل الهوم والـChild)
private struct HomeClearCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: TUHomeStyle.corner, style: .continuous)
                    .fill(Color.white.opacity(0.12).blendMode(.multiply))
            )
            .overlay(
                RoundedRectangle(cornerRadius: TUHomeStyle.corner, style: .continuous)
                    .stroke(Color.white.opacity(0.18), lineWidth: 3)
            )
            .clipShape(RoundedRectangle(cornerRadius: TUHomeStyle.corner, style: .continuous))
    }
}
private extension View { func homeClearCard() -> some View { modifier(HomeClearCardModifier()) } }

// MARK: - IntroView constants
private enum IntroStyle {
    static var centerImageSize: CGFloat = 450
    // 👈 حجم صورة SaturnTomato
    static var startHeight: CGFloat = 50        // 👈 ارتفاع زر Start
    static var startHPad: CGFloat = 140         // 👈 الحواف يمين/يسار (تأثر على عرض الزر)
    static var floatRange: CGFloat = 14         // 👈 مقدار حركة الطفو
    static var floatDuration: Double = 3.0      // 👈 سرعة الطفو
    static var toolbarIconSize: CGFloat = 22    // 👈 حجم زر التعجب
}

struct IntroView: View {
    @State private var goHome = false
    @State private var showInfo = false
    @State private var float = false

    var body: some View {
        NavigationStack {
            ZStack {
                // الخلفية
                Image(UIK.bg)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer(minLength: 60)

                    // صورة SaturnTomato تطفو
                    Image("SaturnTomato")
                        .resizable()
                        .scaledToFit()
                        .frame(width: IntroStyle.centerImageSize, height: IntroStyle.centerImageSize)
                        .shadow(radius: 8, y: 4)
                        .offset(y: float ? -IntroStyle.floatRange : IntroStyle.floatRange)
                        .onAppear {
                            withAnimation(.easeInOut(duration: IntroStyle.floatDuration).repeatForever(autoreverses: true)) {
                                float.toggle()
                            }
                            
                        }
                    
                    Text("Tomato universe")
                    .font(.custom("NanumPen-Regular", size: 50))
                    .foregroundColor(.white)
                    .padding(.top, -130)
                    
                    Text("The 25 minutes focus method")
                        .foregroundColor(.white)
                    Spacer()
                    Spacer()
                    Spacer()
                    Spacer()

                    // زر Start بنفس ستايل الكارد الشفاف
                    Button {
                        goHome = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "play.fill")
                            Text("Start")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: IntroStyle.startHeight) // 👈 الارتفاع هنا
                        .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                    .homeClearCard() // 👈 هنا نستخدم نفس ستايل الكروت
                    .padding(.horizontal, IntroStyle.startHPad)
                    .padding(.bottom, 170)
                }
            }
            // زر التعجب
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showInfo = true } label: {
                        Image(systemName: "exclamationmark.circle")
                            .font(.system(size: IntroStyle.toolbarIconSize, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .homeClearCard()
                }
            }
            .sheet(isPresented: $showInfo) {
                InfoSheetView()
                    .presentationDetents([.medium, .large])
            }
            // الانتقال إلى الهوم
            .navigationDestination(isPresented: $goHome) {
                TUHomeView()
            }
        }
    }
}

// MARK: - Info Sheet
private struct InfoSheetView: View {
    var body: some View {
        VStack(spacing: 16) {
            Capsule()
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 36, height: 5)
                .padding(.top, 8)

            Text("عن التطبيق")
                .font(.headline)

            // 👇 عدل النص حسب ما تبغى
            Text("""
            استخدم جلسات Pomodoro وانطلق للواجهة الرئيسية بالضغط على Start.
            الخلفية والزر بنفس الشفافية المستخدمة في الكروت.
            تقدر تتحكم بالحجم والارتفاع من IntroStyle بالأعلى.
            """)
            .font(.callout)
            .multilineTextAlignment(.leading)
            .padding()
            .homeClearCard()

            Spacer(minLength: 10)
        }
        .padding(.horizontal, 20)
        .background(
            Image(UIK.bg)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        )
    }
}

#Preview {
    IntroView()
}
