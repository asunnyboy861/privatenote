import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    
    var body: some View {
        VStack(spacing: 40) {
            pageIndicator
            
            contentView
            
            actionButtons
        }
        .padding(.bottom, 60)
        .animation(.easeInOut, value: viewModel.currentPage)
    }
    
    private var pageIndicator: some View {
        HStack(spacing: 12) {
            ForEach(0..<viewModel.pages.count, id: \.self) { index in
                Circle()
                    .fill(index == viewModel.currentPage ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut, value: viewModel.currentPage)
            }
        }
        .padding(.top, 40)
    }
    
    private var contentView: some View {
        TabView(selection: $viewModel.currentPage) {
            ForEach(0..<viewModel.pages.count, id: \.self) { index in
                OnboardingPageView(page: viewModel.pages[index])
                    .tag(index)
            }
        }
        #if os(iOS)
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        #endif
        .frame(height: 400)
    }
    
    private var actionButtons: some View {
        HStack(spacing: 20) {
            if viewModel.currentPage < viewModel.pages.count - 1 {
                Button("Skip") {
                    viewModel.skipOnboarding()
                }
                .font(.headline)
                .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Next") {
                    withAnimation {
                        viewModel.nextPage()
                    }
                }
                .font(.headline)
                .padding(.horizontal, 40)
                .padding(.vertical, 12)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            } else {
                Button("Get Started") {
                    viewModel.completeOnboarding()
                }
                .font(.headline)
                .padding(.horizontal, 60)
                .padding(.vertical, 16)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .padding(.horizontal, 40)
    }
}

#Preview {
    OnboardingView()
}
