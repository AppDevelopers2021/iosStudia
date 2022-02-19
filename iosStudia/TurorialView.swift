//
//  TurorialView.swift
//  iosStudia
//
//  Created by 이종우 on 2022/02/18.
//

import SwiftUI

struct TurorialView: View {
    @State private var moveOn: Bool = false
    @State private var index: Int = 0
    var texts = ["과목별로 배운 내용을 노트로 작성하세요".localized, "메모로 중요한 사항을 놓치지 마세요".localized, "과제 및 준비물로 할 일을 정리하세요".localized, "준비되었습니다".localized]
    
    var body: some View {
        ZStack {
            Color(.white)
            
            VStack {
                TabView(selection: $index) {
                    ForEach((0..<4), id: \.self) { index in
                        VStack {
                            Text(texts[index])
                                .font(Font.custom("NanumSquare_ac Bold", size: 30))
                                .padding()
                                .multilineTextAlignment(.center)
                            Image("welcome_" + String(index))
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(minHeight: 400)
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                
                Spacer()
                HStack {
                    if index == 0 {
                        Button("건너뛰기") {
                            UserDefaults.standard.set(true, forKey: "isAppAlreadyLaunchedOnce")
                            self.moveOn = true
                        }
                    } else {
                        Button("이전") {
                            withAnimation {
                                self.index -= 1
                            }
                        }
                    }
                    Spacer()
                    if index == 3 {
                        Button("시작하기") {
                            UserDefaults.standard.set(true, forKey: "isAppAlreadyLaunchedOnce")
                            self.moveOn = true
                        }
                        .font(.system(size: 18, weight: .bold))
                    } else {
                        Button("다음") {
                            withAnimation {
                                self.index += 1
                            }
                        }
                    }
                }
                .foregroundColor(.black)
                .font(.system(size: 18, weight: .medium))
            }
            .padding()
        }
        .navigate(to: LoginView(), when: $moveOn)
    }
}

struct TurorialView_Previews: PreviewProvider {
    static var previews: some View {
        TurorialView()
    }
}
