#include "stm32f1xx_hal.h"

UART_HandleTypeDef huart1;
TIM_HandleTypeDef htim2;

#define PWM_MAX 1000
#define PACKET_HEADER 0xAA
#define PACKET_SIZE 4

/* PID 게인 (펌웨어 튜닝) */
#define PID_KP 3.0f
#define PID_KI 0.5f
#define PID_KD 1.5f
#define PID_BASE_SPEED 800
#define PID_DT 0.01f   /* 제어 루프 주기 10ms */

#define IN1_GPIO_Port GPIOB
#define IN1_Pin GPIO_PIN_12
#define IN2_GPIO_Port GPIOB
#define IN2_Pin GPIO_PIN_13
#define IN3_GPIO_Port GPIOB
#define IN3_Pin GPIO_PIN_14
#define IN4_GPIO_Port GPIOB
#define IN4_Pin GPIO_PIN_15

/* --- UART 패킷 수신 --- */
static volatile uint8_t rx_byte;
static volatile uint8_t rx_buf[PACKET_SIZE];
static volatile uint8_t rx_index = 0;

/*
 * RPi → STM32 패킷 (4 bytes):
 *   [0xAA] [error_hi] [error_lo] [mode]
 *   error: signed 16-bit (person_x - frame_center, 픽셀)
 *   mode:  0=정지, 1=추종
 */
static volatile int16_t target_error = 0;
static volatile uint8_t target_mode = 0;   /* 0=stop, 1=follow */
static volatile uint8_t packet_updated = 0;

/* --- PID 상태 --- */
static float pid_integral = 0.0f;
static float pid_prev_error = 0.0f;

void SystemClock_Config(void);
static void MX_GPIO_Init(void);
static void MX_USART1_UART_Init(void);
static void MX_TIM2_Init(void);

static void Motor_SetSpeed(uint16_t left, uint16_t right);
static void Motor_SetDirection(uint8_t left_dir, uint8_t right_dir);
static void Motor_Stop(void);
static void PID_Reset(void);
static void PID_Update(int16_t error);

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
    if (target_mode == 0) {
      Motor_Stop();
      PID_Reset();
    } else {
      PID_Update(target_error);
    }
    HAL_Delay(10);  /* 100Hz 제어 루프 */
  }
}

/* --- PID 제어기 (STM32에서 실시간 실행) --- */

static void PID_Reset(void) {
  pid_integral = 0.0f;
  pid_prev_error = 0.0f;
}

static void PID_Update(int16_t error) {
  float err = (float)error;

  /* P */
  float p_term = PID_KP * err;

  /* I (anti-windup) */
  pid_integral += err * PID_DT;
  if (pid_integral > 500.0f) pid_integral = 500.0f;
  if (pid_integral < -500.0f) pid_integral = -500.0f;
  float i_term = PID_KI * pid_integral;

  /* D */
  float derivative = (err - pid_prev_error) / PID_DT;
  float d_term = PID_KD * derivative;
  pid_prev_error = err;

  /* PID 출력 → 좌우 PWM 차등 */
  float correction = p_term + i_term + d_term;

  int32_t left_raw  = PID_BASE_SPEED + (int32_t)correction;
  int32_t right_raw = PID_BASE_SPEED - (int32_t)correction;

  /* 방향 결정: 음수 → 역방향 회전 */
  uint8_t left_dir = 0, right_dir = 0;
  if (left_raw < 0) {
    left_dir = 1;
    left_raw = -left_raw;
  }
  if (right_raw < 0) {
    right_dir = 1;
    right_raw = -right_raw;
  }

  /* PWM 클램핑 */
  if (left_raw > PWM_MAX) left_raw = PWM_MAX;
  if (right_raw > PWM_MAX) right_raw = PWM_MAX;

  Motor_SetDirection(left_dir, right_dir);
  Motor_SetSpeed((uint16_t)left_raw, (uint16_t)right_raw);
}

/* --- UART 패킷 파서 ---
 * [0xAA] [error_hi] [error_lo] [mode]
 */
void HAL_UART_RxCpltCallback(UART_HandleTypeDef *huart) {
  if (huart->Instance == USART1) {
    if (rx_index == 0) {
      if (rx_byte == PACKET_HEADER) {
        rx_buf[0] = rx_byte;
        rx_index = 1;
      }
    } else {
      rx_buf[rx_index] = rx_byte;
      rx_index++;
      if (rx_index >= PACKET_SIZE) {
        /* 패킷 완성 */
        int16_t err = (int16_t)((rx_buf[1] << 8) | rx_buf[2]);
        target_error = err;
        target_mode = rx_buf[3];
        packet_updated = 1;
        rx_index = 0;
      }
    }
    HAL_UART_Receive_IT(&huart1, (uint8_t *)&rx_byte, 1);
  }
}

/* --- 모터 제어 --- */

static void Motor_SetSpeed(uint16_t left, uint16_t right) {
  if (left > PWM_MAX) left = PWM_MAX;
  if (right > PWM_MAX) right = PWM_MAX;
  __HAL_TIM_SET_COMPARE(&htim2, TIM_CHANNEL_1, left);
  __HAL_TIM_SET_COMPARE(&htim2, TIM_CHANNEL_2, right);
}

static void Motor_SetDirection(uint8_t left_dir, uint8_t right_dir) {
  if (left_dir == 0) {
    HAL_GPIO_WritePin(IN1_GPIO_Port, IN1_Pin, GPIO_PIN_SET);
    HAL_GPIO_WritePin(IN2_GPIO_Port, IN2_Pin, GPIO_PIN_RESET);
  } else {
    HAL_GPIO_WritePin(IN1_GPIO_Port, IN1_Pin, GPIO_PIN_RESET);
    HAL_GPIO_WritePin(IN2_GPIO_Port, IN2_Pin, GPIO_PIN_SET);
  }
  if (right_dir == 0) {
    HAL_GPIO_WritePin(IN3_GPIO_Port, IN3_Pin, GPIO_PIN_SET);
    HAL_GPIO_WritePin(IN4_GPIO_Port, IN4_Pin, GPIO_PIN_RESET);
  } else {
    HAL_GPIO_WritePin(IN3_GPIO_Port, IN3_Pin, GPIO_PIN_RESET);
    HAL_GPIO_WritePin(IN4_GPIO_Port, IN4_Pin, GPIO_PIN_SET);
  }
}

static void Motor_Stop(void) {
  Motor_SetSpeed(0, 0);
  HAL_GPIO_WritePin(IN1_GPIO_Port, IN1_Pin, GPIO_PIN_RESET);
  HAL_GPIO_WritePin(IN2_GPIO_Port, IN2_Pin, GPIO_PIN_RESET);
  HAL_GPIO_WritePin(IN3_GPIO_Port, IN3_Pin, GPIO_PIN_RESET);
  HAL_GPIO_WritePin(IN4_GPIO_Port, IN4_Pin, GPIO_PIN_RESET);
}

/* --- 주변장치 초기화 --- */

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
