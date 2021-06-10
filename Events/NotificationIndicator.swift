//
//  NotificationIndicator.swift
//  Events
//
//  Created by Elliott Harris on 6/6/21.
//

import SwiftUI

struct NotificationIndicator: View {
    let letter: Character
    let color: UIColor
    let height: CGFloat
    var body: some View {
        Text(String(letter))
            .frame(width: height, height: height)
            .foregroundColor(.white)
            .background(Circle()
                            .foregroundColor(Color(color)))
    }
}

struct NotificationIndicator_Previews: PreviewProvider {
    static var previews: some View {
        NotificationIndicator(letter: "B", color: UIColor.blue, height: 100)
    }
}
