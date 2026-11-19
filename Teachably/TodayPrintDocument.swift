import SwiftUI
import TeachablyCore

enum TodayPrintPage {
    case activity(Activity, FamilyProfile)
    case drawing(DrawingGuide)
    case poem(Poem)

    var id: String {
        switch self {
        case .activity: "activity"
        case .drawing: "drawing"
        case .poem: "poem"
        }
    }

    var label: String {
        switch self {
        case .activity: L10n.string("Activity")
        case .drawing: L10n.string("Drawing")
        case .poem: L10n.string("Poem in English")
        }
    }

    var title: String {
        switch self {
        case .activity(let activity, _): activity.title
        case .drawing(let guide): L10n.string(guide.titleKey)
        case .poem(let poem): poem.title
        }
    }
}

enum TodayPrintDocument {
    static func pdf(pages: [TodayPrintPage], date: String) -> Data? {
        let usesLetter = Locale.current.measurementSystem == .us || Locale.current.region?.identifier == "CA"
        var paper = usesLetter ? CGRect(x: 0, y: 0, width: 612, height: 792) : CGRect(x: 0, y: 0, width: 595, height: 842)
        let area = paper.insetBy(dx: 36, dy: 36)
        let data = NSMutableData()
        guard let consumer = CGDataConsumer(data: data),
              let context = CGContext(consumer: consumer, mediaBox: &paper, nil) else { return nil }

        for page in pages {
            context.beginPDFPage(nil)
            let renderer = ImageRenderer(content: Worksheet(page: page, date: date, width: area.width))
            renderer.render { size, draw in
                let scale = min(1, area.height / size.height)
                context.saveGState()
                context.translateBy(x: area.midX - size.width * scale / 2, y: area.maxY - size.height * scale)
                context.scaleBy(x: scale, y: scale)
                draw(context)
                context.restoreGState()
            }
            context.endPDFPage()
        }
        context.closePDF()
        return data as Data
    }
}

private struct Worksheet: View {
    let page: TodayPrintPage
    let date: String
    let width: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("teachably").font(.system(size: 14, weight: .semibold, design: .rounded))
                Spacer()
                Text(date).font(.system(size: 11))
            }
            Rectangle().fill(.black.opacity(0.35)).frame(height: 0.5)
            VStack(alignment: .leading, spacing: 4) {
                Text(page.label).font(.system(size: 11, weight: .semibold))
                Text(page.title).font(.system(size: 28, weight: .semibold, design: .serif))
            }
            switch page {
            case .activity(let activity, let profile):
                activityContent(activity, profile: profile)
            case .drawing(let guide):
                drawingContent(guide)
            case .poem(let poem):
                Text(poem.source.author).font(.system(size: 12))
                Text(poem.text).font(.system(size: 19, design: .serif)).lineSpacing(5)
            }
        }
        .font(.system(size: 12))
        .foregroundStyle(.black)
        .frame(width: width, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func activityContent(_ activity: Activity, profile: FamilyProfile) -> some View {
        let stages = profile.stages()
        return Group {
            Text(activity.subtitle)
            VStack(alignment: .leading, spacing: 3) {
                Text(activity.takeaway).fontWeight(.semibold)
                Text(activity.parentPrimer)
            }
            section("Gather a few things") {
                Text(activity.materials.isEmpty ? L10n.string("No materials needed") : activity.materials.joined(separator: " · "))
            }
            section("Keep in mind") {
                Text(activity.careNote)
            }
            HStack(alignment: .top, spacing: 20) {
                agePrompt(profile.youngerDisplayName, stage: stages.younger,
                          prompt: activity.prompt(for: stages.younger.band))
                agePrompt(profile.olderDisplayName, stage: stages.older,
                          prompt: activity.prompt(for: stages.older.band))
            }
            section("Big brother’s turn") { Text(activity.siblingPrompt(for: profile)) }
            section("Your activity plan") {
                ForEach(Array(activity.steps.enumerated()), id: \.offset) { index, step in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("\(index + 1). \(step.title)").fontWeight(.semibold)
                            Spacer(minLength: 12)
                            Text(L10n.format("%lld min", step.minutes)).fixedSize()
                        }
                        Text(step.instruction)
                    }
                    .padding(.bottom, 4)
                }
            }
            section("Bring a little of you") {
                Text(activity.personalPrompt)
            }
        }
    }

    private func agePrompt(_ name: String, stage: ChildStage, prompt: AgePrompt) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(name) · \(stage.label)").font(.system(size: 13, weight: .bold))
            Text(prompt.action)
            Text(prompt.question).italic()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func section<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L10n.string(label)).font(.system(size: 13, weight: .bold))
            content()
        }
    }

    private func drawingContent(_ guide: DrawingGuide) -> some View {
        Group {
            Text(L10n.string("Trace the dashes, or make your own marks."))
            HStack(spacing: 12) {
                tracingBox(guide)
                tracingBox(guide)
            }
            RoundedRectangle(cornerRadius: 8).strokeBorder(.black.opacity(0.35))
                .frame(height: 260)
        }
    }

    private func tracingBox(_ guide: DrawingGuide) -> some View {
        guide.stroke(.black.opacity(0.55), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [4, 6]))
            .padding(8)
            .frame(height: 180)
            .background {
                RoundedRectangle(cornerRadius: 8).strokeBorder(.black.opacity(0.35))
            }
    }
}
