// See LICENSE for license details.
#ifndef _DEMOSOC_GPIO_H
#define _DEMOSOC_GPIO_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>

typedef struct {  /*!< GPIO Structure */
    uint32_t INPUT_VAL;
    uint32_t INPUT_EN;
    uint32_t OUTPUT_EN;
    uint32_t OUTPUT_VAL;
    uint32_t PULLUP_EN;
    uint32_t DRIVE;
    uint32_t RISE_IE;
    uint32_t RISE_IP;
    uint32_t FALL_IE;
    uint32_t FALL_IP;
    uint32_t HIGH_IE;
    uint32_t HIGH_IP;
    uint32_t LOW_IE;
    uint32_t LOW_IP;
    uint32_t IOF_EN;
    uint32_t IOF_SEL;
    uint32_t OUTPUT_XOR;
} GPIO_TypeDef;

typedef enum iof_func {
    IOF_SEL_GPIO = 0,
    IOF_SEL_0 = 1,
    IOF_SEL_1 = 2
} IOF_FUNC;


int32_t gpio_iof_config(GPIO_TypeDef* gpio, uint32_t mask, IOF_FUNC func);
int32_t gpio_enable_output(GPIO_TypeDef* gpio, uint32_t mask);
int32_t gpio_enable_input(GPIO_TypeDef* gpio, uint32_t mask);
int32_t gpio_write(GPIO_TypeDef* gpio, uint32_t mask, uint32_t value);
int32_t gpio_toggle(GPIO_TypeDef* gpio, uint32_t mask);


#ifdef __cplusplus
}
#endif
#endif /* _DEMOSOC_GPIO_H */
