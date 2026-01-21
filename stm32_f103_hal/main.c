#include "stm32f1xx_hal.h"

UART_HandleTypeDef huart1;
TIM_HandleTypeDef htim2;

#define PWM_MAX 1000
#define PWM_DEFAULT 800

#define IN1_GPIO_Port GPIOB
#define IN1_Pin GPIO_PIN_12
#define IN2_GPIO_Port GPIOB
#define IN2_Pin GPIO_PIN_13
#define IN3_GPIO_Port GPIOB
#define IN3_Pin GPIO_PIN_14
#define IN4_GPIO_Port GPIOB
#define IN4_Pin GPIO_PIN_15

static volatile uint8_t rx_byte;
static volatile uint8_t current_cmd = 4;

void SystemClock_Config(void);
static void MX_GPIO_Init(void);
static void MX_USART1_UART_Init(void);
static void MX_TIM2_Init(void);

static void Apply_Command(uint8_t cmd);
static void Motor_Stop(void);
static void Motor_LeftOnly(void);
static void Motor_RightOnly(void);
static void Motor_Forward(void);
static void Motor_SetSpeed(uint16_t left, uint16_t right);
static void Motor_LeftForward(void);
static void Motor_RightForward(void);
static void Motor_LeftStop(void);
static void Motor_RightStop(void);

int main(void) {
  HAL_Init();
  SystemClock_Config();

  MX_GPIO_Init();
  MX_USART1_UART_Init();
  MX_TIM2_Init();

  HAL_TIM_PWM_Start(&htim2, TIM_CHANNEL_1);
  HAL_TIM_PWM_Start(&htim2, TIM_CHANNEL_2);

  Motor_Stop();
  HAL_UART_Receive_IT(&huart1, (uint8_t *)&rx_byte, 1);

  while (1) {
    Apply_Command(current_cmd);
    HAL_Delay(10);
  }
}

void HAL_UART_RxCpltCallback(UART_HandleTypeDef *huart) {
  if (huart->Instance == USART1) {
    current_cmd = rx_byte;
    HAL_UART_Receive_IT(&huart1, (uint8_t *)&rx_byte, 1);
  }
}

static void Apply_Command(uint8_t cmd) {
  switch (cmd) {
    case 1:
      Motor_LeftOnly();
      break;
    case 2:
      Motor_RightOnly();
      break;
    case 3:
      Motor_Forward();
      break;
    case 4:
    default:
      Motor_Stop();
      break;
  }
}

static void Motor_SetSpeed(uint16_t left, uint16_t right) {
  if (left > PWM_MAX) {
    left = PWM_MAX;
  }
  if (right > PWM_MAX) {
    right = PWM_MAX;
  }
  __HAL_TIM_SET_COMPARE(&htim2, TIM_CHANNEL_1, left);
  __HAL_TIM_SET_COMPARE(&htim2, TIM_CHANNEL_2, right);
}

static void Motor_LeftForward(void) {
  HAL_GPIO_WritePin(IN1_GPIO_Port, IN1_Pin, GPIO_PIN_SET);
  HAL_GPIO_WritePin(IN2_GPIO_Port, IN2_Pin, GPIO_PIN_RESET);
}

static void Motor_RightForward(void) {
  HAL_GPIO_WritePin(IN3_GPIO_Port, IN3_Pin, GPIO_PIN_SET);
  HAL_GPIO_WritePin(IN4_GPIO_Port, IN4_Pin, GPIO_PIN_RESET);
}

static void Motor_LeftStop(void) {
  HAL_GPIO_WritePin(IN1_GPIO_Port, IN1_Pin, GPIO_PIN_RESET);
  HAL_GPIO_WritePin(IN2_GPIO_Port, IN2_Pin, GPIO_PIN_RESET);
}

static void Motor_RightStop(void) {
  HAL_GPIO_WritePin(IN3_GPIO_Port, IN3_Pin, GPIO_PIN_RESET);
  HAL_GPIO_WritePin(IN4_GPIO_Port, IN4_Pin, GPIO_PIN_RESET);
}

static void Motor_Stop(void) {
  Motor_SetSpeed(0, 0);
  Motor_LeftStop();
  Motor_RightStop();
}

static void Motor_LeftOnly(void) {
  Motor_SetSpeed(0, PWM_DEFAULT);
  Motor_LeftStop();
  Motor_RightForward();
}

static void Motor_RightOnly(void) {
  Motor_SetSpeed(PWM_DEFAULT, 0);
  Motor_LeftForward();
  Motor_RightStop();
}

static void Motor_Forward(void) {
  Motor_SetSpeed(PWM_DEFAULT, PWM_DEFAULT);
  Motor_LeftForward();
  Motor_RightForward();
}

static void MX_TIM2_Init(void) {
  TIM_OC_InitTypeDef sConfigOC = {0};

  htim2.Instance = TIM2;
  htim2.Init.Prescaler = 71;
  htim2.Init.CounterMode = TIM_COUNTERMODE_UP;
  htim2.Init.Period = PWM_MAX - 1;
  htim2.Init.ClockDivision = TIM_CLOCKDIVISION_DIV1;
  htim2.Init.AutoReloadPreload = TIM_AUTORELOAD_PRELOAD_DISABLE;
  if (HAL_TIM_PWM_Init(&htim2) != HAL_OK) {
    Error_Handler();
  }

  sConfigOC.OCMode = TIM_OCMODE_PWM1;
  sConfigOC.Pulse = 0;
  sConfigOC.OCPolarity = TIM_OCPOLARITY_HIGH;
  sConfigOC.OCFastMode = TIM_OCFAST_DISABLE;
  if (HAL_TIM_PWM_ConfigChannel(&htim2, &sConfigOC, TIM_CHANNEL_1) != HAL_OK) {
    Error_Handler();
  }
  if (HAL_TIM_PWM_ConfigChannel(&htim2, &sConfigOC, TIM_CHANNEL_2) != HAL_OK) {
    Error_Handler();
  }
  HAL_TIM_MspPostInit(&htim2);
}

static void MX_USART1_UART_Init(void) {
  huart1.Instance = USART1;
  huart1.Init.BaudRate = 9600;
  huart1.Init.WordLength = UART_WORDLENGTH_8B;
  huart1.Init.StopBits = UART_STOPBITS_1;
  huart1.Init.Parity = UART_PARITY_NONE;
  huart1.Init.Mode = UART_MODE_TX_RX;
  huart1.Init.HwFlowCtl = UART_HWCONTROL_NONE;
  huart1.Init.OverSampling = UART_OVERSAMPLING_16;
  if (HAL_UART_Init(&huart1) != HAL_OK) {
    Error_Handler();
  }
}

static void MX_GPIO_Init(void) {
  GPIO_InitTypeDef GPIO_InitStruct = {0};

  __HAL_RCC_GPIOA_CLK_ENABLE();
  __HAL_RCC_GPIOB_CLK_ENABLE();

  HAL_GPIO_WritePin(GPIOB, IN1_Pin | IN2_Pin | IN3_Pin | IN4_Pin, GPIO_PIN_RESET);

  GPIO_InitStruct.Pin = IN1_Pin | IN2_Pin | IN3_Pin | IN4_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
  HAL_GPIO_Init(GPIOB, &GPIO_InitStruct);
}

void SystemClock_Config(void) {
  RCC_OscInitTypeDef RCC_OscInitStruct = {0};
  RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};

  RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSE;
  RCC_OscInitStruct.HSEState = RCC_HSE_ON;
  RCC_OscInitStruct.HSEPredivValue = RCC_HSE_PREDIV_DIV1;
  RCC_OscInitStruct.PLL.PLLState = RCC_PLL_ON;
  RCC_OscInitStruct.PLL.PLLSource = RCC_PLLSOURCE_HSE;
  RCC_OscInitStruct.PLL.PLLMUL = RCC_PLL_MUL9;
  if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK) {
    Error_Handler();
  }

  RCC_ClkInitStruct.ClockType = RCC_CLOCKTYPE_HCLK | RCC_CLOCKTYPE_SYSCLK |
                                RCC_CLOCKTYPE_PCLK1 | RCC_CLOCKTYPE_PCLK2;
  RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_PLLCLK;
  RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
  RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV2;
  RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV1;
  if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_2) != HAL_OK) {
    Error_Handler();
  }
}

void Error_Handler(void) {
  __disable_irq();
  while (1) {
  }
}
