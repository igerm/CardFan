//
//  ViewController.swift
//  CardFanDemo
//
//  Created by German Azcona on 5/3/22.
//

import UIKit
import CardFan

class ViewController: UIViewController {

    @IBOutlet var cardFan: CardFan!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        cardFan.cardSize = .init(width: 200, height: 350)
        cardFan.minCardScale = 0.5
        cardFan.maxXTranslate = 80
        cardFan.maxRotation = -.pi/12
        cardFan.numberOfVisibleSideCards = 5
        cardFan.cardViews = [
            cardView(backgroundColor: .systemPink),
            cardView(backgroundColor: .systemRed),
            cardView(backgroundColor: .systemOrange),
            cardView(backgroundColor: .systemBrown),
            cardView(backgroundColor: .systemYellow),
            cardView(backgroundColor: .systemGreen),
            cardView(backgroundColor: .systemMint),
            cardView(backgroundColor: .systemCyan),
            cardView(backgroundColor: .systemTeal),
            cardView(backgroundColor: .systemBlue),
            cardView(backgroundColor: .systemPurple),
            cardView(backgroundColor: .systemGray),
        ]
    }

    func cardView(backgroundColor: UIColor) -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = backgroundColor
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.borderWidth = 1
        view.layer.cornerRadius = 20
        return view
    }

}

