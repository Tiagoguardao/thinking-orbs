import SwiftUI
import Testing
import ThinkingOrbsKit

@Test("The public view supports every deterministic rendering control")
func publicViewSupportsRenderingControls() {
    let view = ThinkingOrb(
        state: .searching,
        size: .px64,
        theme: .light,
        speed: 1.25,
        paused: true,
        renderTime: 0.6
    )

    #expect(type(of: view) == ThinkingOrb.self)
}

@Test("Paint mirrors and quantizes source ink to 8-bit grayscale")
func paintMatchesSourceGrayscaleContract() {
    #expect(ThinkingOrbPaint.grayscale(ink: 0.619527, isDark: false) == 158.0 / 255.0)
    #expect(ThinkingOrbPaint.grayscale(ink: 0.619527, isDark: true) == 97.0 / 255.0)
}
