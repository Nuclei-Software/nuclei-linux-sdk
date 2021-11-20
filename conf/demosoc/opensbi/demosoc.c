#include <stdint.h>
#include <stddef.h>
#include "demosoc.h"

#ifndef   __RARELY
  #define __RARELY(exp)                          __builtin_expect((exp), 0)
#endif

int32_t gpio_iof_config(GPIO_TypeDef* gpio, uint32_t mask, IOF_FUNC func)
{
    if (__RARELY(gpio == NULL)) {
        return -1;
    }
    switch (func) {
        case IOF_SEL_GPIO:
            gpio->IOF_EN &= ~mask;
            break;
        case IOF_SEL_0:
            gpio->IOF_SEL &= ~mask;
            gpio->IOF_EN |= mask;
            break;
        case IOF_SEL_1:
            gpio->IOF_SEL |= mask;
            gpio->IOF_EN |= mask;
            break;
        default:
            break;
    }
    return 0;
}

int32_t gpio_enable_output(GPIO_TypeDef* gpio, uint32_t mask)
{
    if (__RARELY(gpio == NULL)) {
        return -1;
    }
    gpio->OUTPUT_EN |= mask;
    gpio->INPUT_EN &= ~mask;
    return 0;
}

int32_t gpio_enable_input(GPIO_TypeDef* gpio, uint32_t mask)
{
    if (__RARELY(gpio == NULL)) {
        return -1;
    }
    gpio->INPUT_EN |= mask;
    gpio->OUTPUT_EN &= ~mask;
    return 0;
}

int32_t gpio_write(GPIO_TypeDef* gpio, uint32_t mask, uint32_t value)
{
    if (__RARELY(gpio == NULL)) {
        return -1;
    }
    // If value != 0, mean set gpio pin high, otherwise set pin low
    if (value) {
        gpio->OUTPUT_VAL |= (mask);
    } else {
        gpio->OUTPUT_VAL &= ~(mask);
    }
    return 0;
}

int32_t gpio_toggle(GPIO_TypeDef* gpio, uint32_t mask)
{
    if (__RARELY(gpio == NULL)) {
        return -1;
    }
    gpio->OUTPUT_VAL = (mask ^ gpio->OUTPUT_VAL);
    return 0;
}