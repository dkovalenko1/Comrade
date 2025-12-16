import UIKit

class CircularProgressView: UIView {


    private var progressLayer = CAShapeLayer()
    private var trackLayer = CAShapeLayer()

    var progressColor: UIColor = .systemRed {
        didSet {
            progressLayer.strokeColor = progressColor.cgColor
        }
    }

    var trackColor: UIColor = UIColor.systemGray5 {
        didSet {
            trackLayer.strokeColor = trackColor.cgColor
        }
    }

    var lineWidth: CGFloat = 12 {
        didSet {
            trackLayer.lineWidth = lineWidth
            progressLayer.lineWidth = lineWidth
        }
    }


    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setupLayers()
    }


    private func setupLayers() {
        // Remove old layers
        trackLayer.removeFromSuperlayer()
        progressLayer.removeFromSuperlayer()

        let center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        let radius = (min(bounds.width, bounds.height) - lineWidth) / 2

        let circularPath = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: -CGFloat.pi / 2,
            endAngle: 2 * CGFloat.pi - CGFloat.pi / 2,
            clockwise: true
        )

        // Track layer (background circle)
        trackLayer.path = circularPath.cgPath
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.strokeColor = trackColor.cgColor
        trackLayer.lineWidth = lineWidth
        trackLayer.lineCap = .round
        layer.addSublayer(trackLayer)

        // Progress layer (animated circle)
        progressLayer.path = circularPath.cgPath
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = progressColor.cgColor
        progressLayer.lineWidth = lineWidth
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 0
        layer.addSublayer(progressLayer)
    }


    func setProgress(_ progress: CGFloat, animated: Bool = true) {
        let clampedProgress = min(max(progress, 0), 1)

        if animated {
            let animation = CABasicAnimation(keyPath: "strokeEnd")
            animation.fromValue = progressLayer.strokeEnd
            animation.toValue = clampedProgress
            animation.duration = 0.3
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            progressLayer.add(animation, forKey: "progressAnimation")
        }

        progressLayer.strokeEnd = clampedProgress
    }

    func reset() {
        setProgress(0, animated: false)
    }

    func complete() {
        setProgress(1, animated: true)
    }
}
