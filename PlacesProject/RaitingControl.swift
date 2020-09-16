//
//  RaitingControl.swift
//  PlacesProject
//
//  Created by Вякулин Сергей on 16.09.2020.
//  Copyright © 2020 Вякулин Сергей. All rights reserved.
//

import UIKit

@IBDesignable class RaitingControl: UIStackView {
    
    private var raitingButtons = [UIButton]() // создаем массив с кнопками для рейтинга
    
    @IBInspectable var starsSize: CGSize = CGSize(width: 44.0, height: 44.0) {
        didSet{
            setupButton() //добавляем наблюдателя didSet чтобы можно было обновлять кнопки в режиме реального времени при изменении значений в StoryBoard
        }
    }
    @IBInspectable var starCount: Int = 5 {
        didSet {
            setupButton()
        }
    }
    
    var raiting = 0 // переменная для хранения рейтинга

    override init(frame: CGRect) { //создаем инициализатор для работы с методом через код
        super.init(frame: frame)
        setupButton() //устанавливаем кнопку при инициализации StackView
    }
    
    //required означает, что супер класс требует обязательного использования данного иницализатора
    required init(coder: NSCoder) { //создаем инициализатор для работы через StoryBoard
        super.init(coder: coder)
        setupButton() //устанавливаем кнопку при инициализации StackView
    }
    
    @objc func raitingButtonTapped(button: UIButton) {
        print("Button pressed 🤮")
        
    }
    
    private func setupButton() { //прописываем метод создания кнопки
        
        //для того чтобы значения обновлялсь после изменений значений в StoryBoard необходимо написать дополнительный цикл удаления существующих элементов
        for button in raitingButtons {
            removeArrangedSubview(button) //удаляем кнопку из StackView
            button.removeFromSuperview() //удаляем кнопку
        }
        
        //по окончанию цикла мы очищаем массив кнопок
        raitingButtons.removeAll()
        
        for _ in 1...starCount{ //делаем цикл до 5 для создания 5 кнопок
            let button = UIButton() // объявляем кнопку
            button.backgroundColor = .green //красим в красный
            
            //добавим програмно констрейнты для кнопки
            button.translatesAutoresizingMaskIntoConstraints = false //отключаем автоматически сгенерированные констрейнты элемента
            button.heightAnchor.constraint(equalToConstant: starsSize.height).isActive = true //привязываем констраинт высоты + включаем его (isActive)
            button.widthAnchor.constraint(equalToConstant: starsSize.width).isActive = true //ширины
            
            button.addTarget(self, action: #selector(raitingButtonTapped(button:)), for: .touchUpInside) // добавляем действие для кнопки
            //self - означает что действие будет производиться из текущего класса
            //selector - само действие которое будет происходить
            //for - какое действие будет описано предыдущими параметрами (в нашем случае нажатие на кнопку)
            
            
            addArrangedSubview(button) //добавляем кнопку в StackView (добавлено в массив представлений, упорядоченных стеком)
            
            raitingButtons.append(button) // добавляем в массив кнопки
        }
    }
}
