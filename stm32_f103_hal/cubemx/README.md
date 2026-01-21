STM32CubeMX project files

This folder contains the CubeMX `.ioc` configuration to regenerate the STM32F103C8T6
project with USART1 (9600), TIM2 PWM channels, and GPIO outputs for L298N control.

Steps
1) Open `coolro_f103c8.ioc` in STM32CubeMX or STM32CubeIDE.
2) Generate code for STM32F103C8T6.
3) Replace the generated `Core/Src/main.c` with `../main.c` logic if needed.

Notes
- USART1: PA9 (TX), PA10 (RX)
- TIM2 PWM: PA0 (CH1), PA1 (CH2)
- L298N IN1..IN4: PB12..PB15
