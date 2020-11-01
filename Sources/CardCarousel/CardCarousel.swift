import SwiftUI

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct LibraryViewContent: LibraryContentProvider {
    @LibraryContentBuilder
    public var views: [LibraryItem] { [
        LibraryItem(
            Card({ EmptyView() }),
            title: "Carousel Card",
            category: .layout,
            matchingSignature: "Card"),
        LibraryItem(
            Carousel{ Card({ EmptyView() }) },
            title: "Carousel",
            category: .layout,
            matchingSignature: "Carousel")
    ] }
//    @LibraryContentBuilder
//    func modifiers(base: ModifierBase) -> [LibraryItem]
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct Card: View {
    private var content: AnyView
    public init<Content:View>(_ content: () -> Content) {
        self.content = AnyView(content())
    }
    public var body: some View {
        ZStack(alignment: . center) {
            Color(UIColor.systemBackground)
            content
        }
        .frame(minHeight: 50, idealHeight: 400, maxHeight: 800, alignment: .bottom)
        .cornerRadius(10)
        .shadow(radius: 3)
    }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct Carousel: View {
    private var cards: [Card]
    @GestureState private var dragState = DragState.inactive
    @State private var carouselLocation = 0
    private let ratio: CGFloat = 0.85,
                cardWidth: CGFloat = 300,
                offset: CGFloat = 20
    init(@CarouselViewBuilder cards: () -> [Card]) {
        self.cards = cards()
    }
    private func onDragEnded(drag: DragGesture.Value) {
        let dragThreshold:CGFloat = 200
        if drag.predictedEndTranslation.width > dragThreshold || drag.translation.width > dragThreshold {
            carouselLocation = carouselLocation == 0 ? cards.count : carouselLocation - 1
        } else if (drag.predictedEndTranslation.width) < (-1 * dragThreshold) || (drag.translation.width) < (-1 * dragThreshold) {
            carouselLocation = carouselLocation == cards.count ? 0 : carouselLocation + 1
        }
    }
    
    public var body: some View {
        ZStack{
            ForEach(0..<cards.count){ i in
                self.cards[i]
                    .frame(width: cardWidth)
                    .scaleEffect(i == relativeLoc() ? 1 : ratio)
                    .opacity(self.getOpacity(i))
                    .offset(x: self.getOffset(i))
                    .animation(.interpolatingSpring(stiffness: 300.0, damping: 30.0, initialVelocity: 10.0))
            }
        }.gesture(
            DragGesture()
                .updating($dragState) { drag, state, transaction in
                    state = .dragging(translation: drag.translation)
                }.onEnded(onDragEnded)
        )
    }
    
    private func relativeLoc() -> Int {
        ((cards.count * 10000) + carouselLocation) % cards.count
    }
    private func getOpacity(_ i:Int) -> Double{
        ([(i+1)-cards.count,(i+2)-cards.count,(i-2)+cards.count,(i-1)+cards.count]+Array(i-2...i+2)).contains(relativeLoc()) ? 1 : 0
    }
    private func getOffset(_ i:Int) -> CGFloat {
        let adjustment = (cardWidth-cardWidth*ratio)/2 // Adjustment for center card width
        let offsetBy: (Int) -> CGFloat = {
            let thisOffset = (CGFloat($0) * (cardWidth * ratio + offset) + CGFloat($0.signum()) * adjustment)
            return dragState.translation.width + thisOffset
        }
        //This sets up the central offset
        if (i) == relativeLoc() {
            return self.dragState.translation.width
        }
        //This set up the offset +1
        else if (i) == relativeLoc() + 1
                    || (relativeLoc() == cards.count - 1 && i == 0) {
            return offsetBy(1)
        }
        //This set up the offset -1
        else if (i) == relativeLoc() - 1
                    || (relativeLoc() == 0 && (i) == cards.count - 1) {
            return offsetBy(-1)
        }
        //These set up the offset for +2
        else if (i) == relativeLoc() + 2
                    || (relativeLoc() == cards.count-1 && i == 1)
                    || (relativeLoc() == cards.count-2 && i == 0) {
            return offsetBy(2)
        }
        //These set up the offset for -2
        else if (i) == relativeLoc() - 2
                    || (relativeLoc() == 1 && i == cards.count-1)
                    || (relativeLoc() == 0 && i == cards.count-2) {
            return offsetBy(-2)
        }
        //These set up the offset for +3
        else if (i) == relativeLoc() + 3
                    || (relativeLoc() == cards.count-1 && i == 2)
                    || (relativeLoc() == cards.count-2 && i == 1)
                    || (relativeLoc() == cards.count-3 && i == 0) {
            return offsetBy(3)
        }
        //These set up the offset for -3
        else if (i) == relativeLoc() - 3
                    || (relativeLoc() == 2 && i == cards.count-1)
                    || (relativeLoc() == 1 && i == cards.count-2)
                    || (relativeLoc() == 0 && i == cards.count-3) {
            return offsetBy(-3)
        }
        //This is the remainder
        else {
            return 10000
        }
    }
    
    private enum DragState {
        case inactive, dragging(translation: CGSize)
        
        var translation: CGSize {
            switch self {
            case .inactive: return .zero
            case .dragging(let translation): return translation
            }
        }
        var isDragging: Bool {
            switch self {
            case .inactive: return false
            case .dragging: return true
            }
        }
    }
    @_functionBuilder public struct CarouselViewBuilder {
        public static func buildBlock(_ segments: Card...) -> [Card] {
            var array = [Card]()
            segments.forEach { array.append($0) }
            return array
        }
    }
}
