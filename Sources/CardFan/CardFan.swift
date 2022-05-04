//
//  CardFan.swift
//
//
//  Created by German Azcona on 4/25/22.
//

import UIKit

/// Shows a stack of `UIView`s a fan of cards.
public class CardFan: UIView, UIScrollViewDelegate {

    /// Number of visible cards you will see at each side
    public var numberOfVisibleSideCards: UInt = 3 { didSet { reaplyCardsTransforms() } }

    /// How small the cards get as they are swiped left/right. Default values is 0.68 according to figma
    public var minCardScale: CGFloat = 0.68 { didSet { reaplyCardsTransforms() } }

    /// How much do cards get moves left/right as they are swipped.
    public var maxXTranslate: CGFloat = 40 { didSet { reaplyCardsTransforms() } }

    /// How much are cards rotated (in radians) as they go left/right.
    public var maxRotation: CGFloat = -.pi/20.0 { didSet { reaplyCardsTransforms() } }

    /// It applies horizontal offset corrections as the user scrolls through the stack of cards so
    /// when the top card is the left most card, it is aligned to the CardFan view's left edge and
    /// when the top card is the right most card, it is aligned to the CardFan view's right edge.
    public var appliesAlignmentCorrection: Bool = false { didSet { reaplyCardsTransforms() } }

    /// The index of the card that's visible
    public private(set) var currentIndex: Int = 0

    /// The array of views that will be used as cards.
    /// Make sure the views doesn't contain height and width constraints.
    public var cardViews: [UIView] = [] {
        willSet {
            cardViews.forEach { $0.removeFromSuperview() }
        }
        didSet {
            cardViews.forEach { card in
                scrollView.addSubview(card)
            }
            relayoutCards()
            reaplyCardsTransforms()
        }
    }

    /// The size of the cards.
    public var cardSize: CGSize = .init(width: 300, height: 370) {
        didSet {
            relayoutCards()
            reaplyCardsTransforms()
        }
    }

    /// This will be called as the user drags the cards so the views can be stylized depending on the dragging progress.
    /// - parameter UIView: the view you can apply the styling to.
    /// - parameter Int: The index of the card.
    /// - parameter CGFloat: the progress from the center. If it's zero is in the center and the selected index.
    public var cardViewStylizer: ((UIView, Int, CGFloat) -> Void)?

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.automaticallyAdjustsScrollIndicatorInsets = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.isPagingEnabled = true
        scrollView.clipsToBounds = false
        scrollView.delegate = self
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()

    private var cardConstraints = [NSLayoutConstraint]()

    private var indexForCardBeingSwipped: Int = 0

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        relayoutCards()
        reaplyCardsTransforms()
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        reaplyCardsTransforms()
    }

    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if isUserInteractionEnabled == false { return nil }
        return scrollView
    }
}

private extension CardFan {

    func setupViews() {

        clipsToBounds = false
        translatesAutoresizingMaskIntoConstraints = false

        addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.frameLayoutGuide.topAnchor.constraint(equalTo: topAnchor),
            scrollView.frameLayoutGuide.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.frameLayoutGuide.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
    }
    var pageWidth: CGFloat { round(cardSize.width * 1.25) }
    var pageX: CGFloat { scrollView.frame.width / 2.0 - cardSize.width / 2.0 }

    func relayoutCards() {

        NSLayoutConstraint.deactivate(cardConstraints)

        let contentWidth = CGFloat(cardViews.count) * pageWidth
        cardConstraints = [
            scrollView.contentLayoutGuide.widthAnchor.constraint(equalToConstant: contentWidth),
            scrollView.contentLayoutGuide.heightAnchor.constraint(equalToConstant: cardSize.height),
            scrollView.frameLayoutGuide.widthAnchor.constraint(equalToConstant: pageWidth)
        ]

        cardViews.forEach { card in
            cardConstraints.append(card.widthAnchor.constraint(equalToConstant: cardSize.width))
            cardConstraints.append(card.heightAnchor.constraint(equalToConstant: cardSize.height))
            cardConstraints.append(card.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor))
            cardConstraints.append(
                card.leftAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leftAnchor,
                                           constant: pageX)
            )
        }
        NSLayoutConstraint.activate(cardConstraints)
    }

    func reaplyCardsTransforms() {

        guard cardSize != .zero else { return }

        let offsetPercent = scrollView.contentOffset.x / pageWidth
        let currentIndexFloat = round(offsetPercent)
        let currentIndex = Int(currentIndexFloat)
        self.currentIndex = max(0, min(cardViews.endIndex-1, currentIndex))

        if offsetPercent == currentIndexFloat || abs(offsetPercent - CGFloat(indexForCardBeingSwipped)) > 1.0 {
            indexForCardBeingSwipped = currentIndex
        }

        cardViews.enumerated().forEach { index, cardView in

            var transform = CGAffineTransform.identity.translatedBy(x: scrollView.contentOffset.x, y: 0)

            // extra translate
            let extraXTranslate = extraTranslate()
            transform = transform.translatedBy(x: extraXTranslate, y: 0)

            // determine if this is the card that's being swiped
            let progressForSwipe = offsetPercent - CGFloat(indexForCardBeingSwipped)
            let indexIsFirstPosition = index == 0
            let indexIsLastPosition = index == cardViews.count - 1
            let indexIsNotFirstNorLast = index > 0 && index < cardViews.count - 1
            let shouldApplySwipeTransform = index == indexForCardBeingSwipped && (
                (indexIsFirstPosition && progressForSwipe > 0) ||
                (indexIsLastPosition && progressForSwipe < 0) ||
                indexIsNotFirstNorLast
            )
            if shouldApplySwipeTransform {
                // if it's being swiped, separate progress in two:
                // 1. it goes from 0 to MAX offset.
                // 2. it goes from MAX offset to where it would land if it wasn't being animated.

                if abs(progressForSwipe) < 0.5 {
                    transform = applyFirstSwipeTransform(to: transform, cardIndex: index)
                } else {
                    transform = applySecondSwipeTransform(to: transform, cardIndex: index)
                }
            } else {
                transform = applyStandardTransform(to: transform, cardIndex: index)
            }

            cardView.transform = transform
            cardView.layer.allowsEdgeAntialiasing = true

            // show/hide details on card
            stylize(cardView: cardView, index: index)
        }

        // fix z position
        fixZPosition()

        hideNotVisibleCards()
    }

    // MARK: - Transition functions

    /// Converts a float with values between [-1, 1] to another float with values between [-1, 1].
    /// On -1, 1 and 0, the values are going to be the same.
    /// But all other values will vary by adding curves depending on easeOut function used.
    func easedOut(progress: CGFloat) -> CGFloat {
        EaseOutFunctions.easeOutSine(progress)
    }

    /// This is extra X translate so the first and last card align to the CardFan view as the user swipes left/right.
    func extraTranslate() -> CGFloat {

        guard appliesAlignmentCorrection else { return 0 }

        // this only works if there are several card. Otherwise we will be dividing by Zero on extraXTranslateProgress.
        guard cardViews.count > 1 else { return 0 }

        // this is extra X translate so the first and last card align to the CardFan view.
        let maxExtraXTranslate: CGFloat = (scrollView.frame.origin.x+pageX) * 2.0
        let extraXTranslateProgress = 0.5 -
            scrollView.contentOffset.x / (scrollView.contentSize.width - pageWidth)
        let extraXTranslate = -maxExtraXTranslate*extraXTranslateProgress
        return extraXTranslate
    }

    func fixZPosition() {
        cardViews
            .enumerated()
            .sorted {
                let distanceToCurrentOffset1 = scrollView.contentOffset.x - CGFloat($0.0) * pageWidth
                let distanceToCurrentOffset2 = scrollView.contentOffset.x - CGFloat($1.0) * pageWidth
                return abs(distanceToCurrentOffset1) > abs(distanceToCurrentOffset2)
            }
            .forEach { _, cardView in
                cardView.superview?.bringSubviewToFront(cardView)
            }
    }

    func hideNotVisibleCards() {
        cardViews
            .enumerated()
            .forEach { index, cardView in
                let distanceToOffset = abs(scrollView.contentOffset.x - pageWidth * CGFloat(index))
                let maxDistance = abs(pageWidth * CGFloat(numberOfVisibleSideCards+1))
                cardView.isHidden = distanceToOffset >= maxDistance
            }
    }

    private func stylize(cardView: UIView, index: Int) {
        // progress
        let progress = standardTransformProgress(for: index)

        cardViewStylizer?(cardView, index, progress)
    }

    // MARK: - Standard Transforms
    // Standard transitions are those that are slighlty offset, scaled and rotated as the cards go away

    func applyStandardTransform(to transform: CGAffineTransform, cardIndex index: Int) -> CGAffineTransform {

        var transform = transform

        // progress
        let progress = standardTransformProgress(for: index)

        // x translation
        let xTranslate = standardXTranslate(for: progress)
        transform = transform.translatedBy(x: xTranslate, y: 0)

        // size translation
        let scale = standardScale(for: progress)
        transform = transform.scaledBy(x: scale, y: scale)

        // rotation translation
        let rotation = standardRotation(for: progress)
        transform = transform.rotated(by: rotation)

        return transform
    }

    /// Progress percentage (between -1 and 1) to be applied to any transform
    func standardTransformProgress(for cardIndex: Int) -> CGFloat {

        let cardPosition = CGFloat(cardIndex) * pageWidth
        let maxDistance = pageWidth * CGFloat(numberOfVisibleSideCards)
        let distanceToCurrent = scrollView.contentOffset.x - cardPosition
        let progress = distanceToCurrent / maxDistance
        let cappedProgress = max(-1, min(1, progress))
        // We don't return cappedProgress. Because that is a linear transformation and we want to get fancy the
        // transformation curve
        return cappedProgress
    }

    func standardXTranslate(for progress: CGFloat) -> CGFloat {
        let easedOutProgress = easedOut(progress: progress)
        return -maxXTranslate*easedOutProgress
    }

    func standardScale(for progress: CGFloat) -> CGFloat {
        // We need to scales from min to 1.0
        let signlessProgress = abs(progress) // remove sign
        let rangeToScale = 1.0 - minCardScale // this is the range it will scale (range goes from min to 1)
                                              // But this goes from 0 to (1-min).
        let rangeForProgress = rangeToScale * signlessProgress // we have calculated how much it will scale.

        // to go from (0 -> 1-min) to (min -> 1.0) we do:
        let scale = 1.0 - rangeForProgress
        return scale
    }

    func standardRotation(for progress: CGFloat) -> CGFloat {
        maxRotation * progress
    }

    // MARK: - Swipe Transform, part 1

    func applyFirstSwipeTransform(to transform: CGAffineTransform, cardIndex index: Int) -> CGAffineTransform {

        let offsetPercent = scrollView.contentOffset.x / pageWidth
        let progressForFullSwipe = offsetPercent - CGFloat(indexForCardBeingSwipped)

        let progressForHalfSwipe = progressForFullSwipe / 0.5

        var transform = transform

        // x translation
        let xTranslate = firstSwipeTransform(for: progressForHalfSwipe)
        transform = transform.translatedBy(x: xTranslate, y: 0)

        // size translation
        let scale = firstSwipeScale(for: progressForHalfSwipe)
        transform = transform.scaledBy(x: scale, y: scale)

        // rotation translation
        let rotation = firstSwipeRotation(for: progressForHalfSwipe)
        transform = transform.rotated(by: rotation)

        return transform
    }

    func firstSwipeTransform(for progress: CGFloat) -> CGFloat {
        -(pageWidth * 0.85) * progress
    }

    func firstSwipeScale(for progress: CGFloat) -> CGFloat {
        1.0 - (1.0 - 0.75) * abs(progress)
    }

    func firstSwipeRotation(for progress: CGFloat) -> CGFloat {
        maxRotation * progress * 2
    }

    // MARK: - Swipe Transform, part 2

    func applySecondSwipeTransform(to transform: CGAffineTransform, cardIndex index: Int) -> CGAffineTransform {

        let offsetPercent = scrollView.contentOffset.x / pageWidth
        let progressForFullSwipe = offsetPercent - CGFloat(indexForCardBeingSwipped)
        let sign: CGFloat = progressForFullSwipe < 0 ? -1 : 1

        // from -1/1 to 0
        let progressForSecondSwipe = sign * (abs(progressForFullSwipe) - 0.5) / 0.5

        // from 0 to 1/-1
        let progressForSecondSwipeInverted = (1.0 - abs(progressForSecondSwipe)) * sign

        // sigmoid max. the progress for the card to be offset
        let destinationProgress = 1.0/CGFloat(numberOfVisibleSideCards) * sign

        var transform = transform

        // x translation
        let maxXTranslate = standardXTranslate(for: destinationProgress)
        let minXTranslate = firstSwipeTransform(for: 1.0)
        let xTranslateDelta = abs(abs(maxXTranslate)-abs(minXTranslate))
        let xTranslate = maxXTranslate + xTranslateDelta * progressForSecondSwipeInverted * -1.0
        transform = transform.translatedBy(x: xTranslate, y: 0)

        // size translation
        let maxScale = standardScale(for: destinationProgress)
        let minScale = firstSwipeScale(for: 1.0)
        let scaleDelta = abs(abs(maxScale)-abs(minScale))
        let scale = maxScale + scaleDelta * abs(progressForSecondSwipeInverted) * -1
        transform = transform.scaledBy(x: scale, y: scale)

        // rotation translation
        let maxRotation = standardRotation(for: destinationProgress)
        let minRotation = firstSwipeRotation(for: 1.0)
        let rotationDelta = abs(abs(maxRotation)-abs(minRotation))
        let rotation = maxRotation + rotationDelta * progressForSecondSwipeInverted * -1.0
        transform = transform.rotated(by: rotation)

        return transform
    }
}
