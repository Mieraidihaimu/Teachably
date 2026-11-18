import SwiftUI
import TeachablyCore
import UIKit

struct TodayPrintView: View {
    @EnvironmentObject private var store: FamilyStore
    @State private var includeActivity = true
    @State private var includeDrawing = true
    @State private var includePoem = true
    @State private var printAnchor = UIView()
    @State private var showingPrintOptions = false
    @State private var showPrintError = false

    private static let shortPoems = ((try? PoemCatalog.load()) ?? []).filter { $0.level == .zero || $0.level == .one }

    var body: some View {
        let date = Date.now
        let day = Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0
        let guides = DrawingGuide.allCases
        let drawing = TodayPrintPage.drawing(guides[day % guides.count])
        let activity = store.today.map(TodayPrintPage.activity)
        let poems = Self.shortPoems
        let poem = poems.isEmpty ? nil : TodayPrintPage.poem(poems[day % poems.count])
        let selectedPages = [includeActivity ? activity : nil, includeDrawing ? drawing : nil, includePoem ? poem : nil]
            .compactMap { $0 }
        let dateLabel = date.formatted(date: .long, time: .omitted)

        List {
            Section(dateLabel) {
                if let activity {
                    pageToggle(activity, isOn: $includeActivity)
                }
                pageToggle(drawing, isOn: $includeDrawing)
                if let poem {
                    pageToggle(poem, isOn: $includePoem)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Palette.background)
        .navigationTitle(L10n.string("Print for today"))
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button {
                printPages(selectedPages, date: dateLabel)
            } label: {
                Label(L10n.string("Print"), systemImage: "printer")
            }
            .buttonStyle(PrimaryButtonStyle())
            .accessibilityIdentifier("print.today.open-options")
            .disabled(selectedPages.isEmpty || showingPrintOptions)
            .opacity(selectedPages.isEmpty ? 0.45 : 1)
            .frame(maxWidth: 480)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(Palette.background)
            .background(PrintAnchor(view: printAnchor).allowsHitTesting(false).accessibilityHidden(true))
        }
        .task { store.refreshToday() }
        .alert(L10n.string("Couldn’t print"), isPresented: $showPrintError) {
            Button(L10n.string("OK"), role: .cancel) { }
        } message: {
            Text(L10n.string("Check that an AirPrint printer is available and try again."))
        }
    }

    private func pageToggle(_ page: TodayPrintPage, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 4) {
                Text(page.label).font(.headline)
                Text(page.title).font(.subheadline).foregroundStyle(Palette.muted)
            }
            .padding(.vertical, 4)
        }
        .accessibilityIdentifier("print.today.\(page.id)")
    }

    private func printPages(_ pages: [TodayPrintPage], date: String) {
        guard !pages.isEmpty, !showingPrintOptions else { return }
        guard UIPrintInteractionController.isPrintingAvailable, printAnchor.window != nil,
              let pdf = TodayPrintDocument.pdf(pages: pages, date: date),
              UIPrintInteractionController.canPrint(pdf) else {
            showPrintError = true
            return
        }

        let controller = UIPrintInteractionController.shared
        let info = UIPrintInfo(dictionary: nil)
        info.jobName = L10n.string("Print for today")
        info.outputType = .grayscale
        info.orientation = .portrait
        controller.printInfo = info
        controller.printingItem = pdf

        showingPrintOptions = true
        let finished: UIPrintInteractionController.CompletionHandler = { _, _, error in
            showingPrintOptions = false
            showPrintError = error != nil
        }
        let presented = printAnchor.traitCollection.userInterfaceIdiom == .pad
            ? controller.present(from: printAnchor.bounds, in: printAnchor, animated: true, completionHandler: finished)
            : controller.present(animated: true, completionHandler: finished)
        if !presented {
            showingPrintOptions = false
            showPrintError = true
        }
    }
}

private struct PrintAnchor: UIViewRepresentable {
    let view: UIView

    func makeUIView(context: Context) -> UIView { view }
    func updateUIView(_ uiView: UIView, context: Context) { }
}
