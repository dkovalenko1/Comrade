//
//  SliderRowView.swift
//  Comrade
//
//  Created by Bohdan Hupalo on 15.12.2025.
//


import UIKit
import SnapKit

final class SliderRowView: UIView {
    
    var onValueChange: ((Int) -> Void)?
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = .label
        return label
    }()
    
    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(ofSize: 15, weight: .bold)
        label.textColor = UIColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0)
        label.textAlignment = .right
        return label
    }()
    
    private lazy var slider: UISlider = {
        let slider = UISlider()
        slider.minimumTrackTintColor = UIColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0)
        slider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
        return slider
    }()
    
    private let step: Float
    
    init(title: String, min: Float, max: Float, current: Int, step: Float = 1.0) {
        self.step = step
        super.init(frame: .zero)
        
        titleLabel.text = title
        slider.minimumValue = min
        slider.maximumValue = max
        slider.value = Float(current)
        valueLabel.text = "\(current) min"
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(titleLabel)
        addSubview(valueLabel)
        addSubview(slider)
        
        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
        }
        
        valueLabel.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview()
        }
        
        slider.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(30)
        }
    }
    
    @objc private func sliderChanged() {
        let roundedValue = round(slider.value / step) * step
        slider.value = roundedValue
        let intVal = Int(roundedValue)
        
        valueLabel.text = "\(intVal) min"
        onValueChange?(intVal)
    }
}
