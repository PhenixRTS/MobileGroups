//
//  Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

@testable
import Phenix_Groups
import XCTest

class ControlButtonTests: XCTestCase {
    func testInitialValues() {
        // When
        let button = ControlButton()

        // Then
        XCTAssertNil(button.onStateImage)
        XCTAssertNil(button.offStateImage)
        XCTAssertEqual(button.onStateBorderColor, .clear)
        XCTAssertEqual(button.offStateBorderColor, .clear)
        XCTAssertEqual(button.onStateHighlightedBorderColor, .clear)
        XCTAssertEqual(button.offStateHighlightedBorderColor, .clear)
        XCTAssertEqual(button.onStateBackgroundColor, .clear)
        XCTAssertEqual(button.offStateBackgroundColor, .clear)
        XCTAssertEqual(button.onStateHighlightedBackgroundColor, .clear)
        XCTAssertEqual(button.offStateHighlightedBackgroundColor, .clear)
        XCTAssertEqual(button.controlState, .on)
    }

    func testSetImageForOnState() {
        // Given
        let button = ControlButton()
        let image = UIImage()

        // When
        button.setImage(image, for: .on)

        // Then
        XCTAssertEqual(button.onStateImage, image)
    }

    func testSetImageForOffState() {
        // Given
        let button = ControlButton()
        let image = UIImage()

        // When
        button.setImage(image, for: .off)

        // Then
        XCTAssertEqual(button.offStateImage, image)
    }

    func testSetBorderColorForOnState() {
        // Given
        let button = ControlButton()
        let color = UIColor.green

        // When
        button.setBorderColor(color, for: .on)

        // Then
        XCTAssertEqual(button.onStateBorderColor, color)
    }

    func testSetBorderColorForOffState() {
        // Given
        let button = ControlButton()
        let color = UIColor.green

        // When
        button.setBorderColor(color, for: .off)

        // Then
        XCTAssertEqual(button.offStateBorderColor, color)
    }

    func testSetHighlightedBorderColorForOnState() {
        // Given
        let button = ControlButton()
        let color = UIColor.green

        // When
        button.setHighlightedBorderColor(color, for: .on)

        // Then
        XCTAssertEqual(button.onStateHighlightedBorderColor, color)
    }

    func testSetHighlightedBorderColorForOffState() {
        // Given
        let button = ControlButton()
        let color = UIColor.green

        // When
        button.setHighlightedBorderColor(color, for: .off)

        // Then
        XCTAssertEqual(button.offStateHighlightedBorderColor, color)
    }

    func testSetBackgroundColorForOnState() {
        // Given
        let button = ControlButton()
        let color = UIColor.green

        // When
        button.setBackgroundColor(color, for: .on)

        // Then
        XCTAssertEqual(button.onStateBackgroundColor, color)
    }

    func testSetBackgroundColorForOffState() {
        // Given
        let button = ControlButton()
        let color = UIColor.green

        // When
        button.setBackgroundColor(color, for: .off)

        // Then
        XCTAssertEqual(button.offStateBackgroundColor, color)
    }

    func testSetHighlightedBackgroundColorForOnState() {
        // Given
        let button = ControlButton()
        let color = UIColor.green

        // When
        button.setHighlightedBackgroundColor(color, for: .on)

        // Then
        XCTAssertEqual(button.onStateHighlightedBackgroundColor, color)
    }

    func testSetHighlightedBackgroundColorForOffState() {
        // Given
        let button = ControlButton()
        let color = UIColor.green

        // When
        button.setHighlightedBackgroundColor(color, for: .off)

        // Then
        XCTAssertEqual(button.offStateHighlightedBackgroundColor, color)
    }

    func testCurrentImageReturnsCorrectlyForOnState() {
        // Given
        let button = ControlButton()
        let image1 = UIImage(systemName: "mic.fill")
        let image2 = UIImage(systemName: "mic.slash.fill")

        button.controlState = .on

        // When
        button.setImage(image1, for: .on)
        button.setImage(image2, for: .off)

        // Then
        XCTAssertEqual(button.currentImage, image1)
        XCTAssertNotEqual(button.currentImage, image2)
    }

    func testCurrentImageReturnsCorrectlyForOffState() {
        // Given
        let button = ControlButton()
        let image1 = UIImage(systemName: "mic.fill")
        let image2 = UIImage(systemName: "mic.slash.fill")

        button.controlState = .off

        // When
        button.setImage(image1, for: .on)
        button.setImage(image2, for: .off)

        // Then
        XCTAssertNotEqual(button.currentImage, image1)
        XCTAssertEqual(button.currentImage, image2)
    }

    func testCurrentBorderColorReturnsCorrectlyForOnState() {
        // Given
        let button = ControlButton()
        let color1 = UIColor.white
        let color2 = UIColor.black

        button.controlState = .on

        // When
        button.setBorderColor(color1, for: .on)
        button.setBorderColor(color2, for: .off)

        // Then
        XCTAssertEqual(button.currentBorderColor, color1.cgColor)
        XCTAssertNotEqual(button.currentBorderColor, color2.cgColor)
    }

    func testCurrentBorderColorReturnsCorrectlyForOffState() {
        // Given
        let button = ControlButton()
        let color1 = UIColor.white
        let color2 = UIColor.black

        button.controlState = .off

        // When
        button.setBorderColor(color1, for: .on)
        button.setBorderColor(color2, for: .off)

        // Then
        XCTAssertNotEqual(button.currentBorderColor, color1.cgColor)
        XCTAssertEqual(button.currentBorderColor, color2.cgColor)
    }

    func testCurrentHighlightedBorderColorReturnsCorrectlyForOnState() {
        // Given
        let button = ControlButton()
        let color1 = UIColor.white
        let color2 = UIColor.black

        button.controlState = .on

        // When
        button.setHighlightedBorderColor(color1, for: .on)
        button.setHighlightedBorderColor(color2, for: .off)

        // Then
        XCTAssertEqual(button.currentHighlightedBorderColor, color1.cgColor)
        XCTAssertNotEqual(button.currentHighlightedBorderColor, color2.cgColor)
    }

    func testCurrentHighlightedBorderColorReturnsCorrectlyForOffState() {
        // Given
        let button = ControlButton()
        let color1 = UIColor.white
        let color2 = UIColor.black

        button.controlState = .off

        // When
        button.setHighlightedBorderColor(color1, for: .on)
        button.setHighlightedBorderColor(color2, for: .off)

        // Then
        XCTAssertNotEqual(button.currentHighlightedBorderColor, color1.cgColor)
        XCTAssertEqual(button.currentHighlightedBorderColor, color2.cgColor)
    }

    func testCurrentBackgroundColorReturnsCorrectlyForOnState() {
        // Given
        let button = ControlButton()
        let color1 = UIColor.white
        let color2 = UIColor.black

        button.controlState = .on

        // When
        button.setBackgroundColor(color1, for: .on)
        button.setBackgroundColor(color2, for: .off)

        // Then
        XCTAssertEqual(button.currentBackgroundColor, color1)
        XCTAssertNotEqual(button.currentBackgroundColor, color2)
    }

    func testCurrentBackgroundColorReturnsCorrectlyForOffState() {
        // Given
        let button = ControlButton()
        let color1 = UIColor.white
        let color2 = UIColor.black

        button.controlState = .off

        // When
        button.setBackgroundColor(color1, for: .on)
        button.setBackgroundColor(color2, for: .off)

        // Then
        XCTAssertNotEqual(button.currentBackgroundColor, color1)
        XCTAssertEqual(button.currentBackgroundColor, color2)
    }

    func testCurrentHighlightedBackgroundColorReturnsCorrectlyForOnState() {
        // Given
        let button = ControlButton()
        let color1 = UIColor.white
        let color2 = UIColor.black

        button.controlState = .on

        // When
        button.setHighlightedBackgroundColor(color1, for: .on)
        button.setHighlightedBackgroundColor(color2, for: .off)

        // Then
        XCTAssertEqual(button.currentHighlightedBackgroundColor, color1)
        XCTAssertNotEqual(button.currentHighlightedBackgroundColor, color2)
    }

    func testCurrentHighlightedBackgroundColorReturnsCorrectlyForOffState() {
        // Given
        let button = ControlButton()
        let color1 = UIColor.white
        let color2 = UIColor.black

        button.controlState = .off

        // When
        button.setHighlightedBackgroundColor(color1, for: .on)
        button.setHighlightedBackgroundColor(color2, for: .off)

        // Then
        XCTAssertNotEqual(button.currentHighlightedBackgroundColor, color1)
        XCTAssertEqual(button.currentHighlightedBackgroundColor, color2)
    }

    func testRefreshStateRepresentationSetsCorrectImage() {
        // Given
        let button = ControlButton()
        let image1 = UIImage(named: "mic")

        XCTAssertNil(button.imageView?.image)

        // When
        button.setImage(image1, for: .on)
        button.refreshStateRepresentation()

        // Then
        XCTAssertEqual(button.imageView?.image, image1)
    }

    func testControlStateChangesDoUpdateImage() {
        // Given
        let button = ControlButton()
        let image1 = UIImage(systemName: "mic.fill")
        let image2 = UIImage(systemName: "mic.slash.fill")

        button.setImage(image1, for: .on)
        button.setImage(image2, for: .off)

        // When
        button.controlState = .on

        // Then
        XCTAssertEqual(button.imageView?.image, image1)

        // When
        button.controlState = .off

        // Then
        XCTAssertEqual(button.imageView?.image, image2)
    }
}
