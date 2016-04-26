# Coffeeimp

Impified _Jura IMPRESSA J9.3_. 

## Building

```
npm i -g Builder
pleasebuild agent.builder.nut > dist/agent.nut
pleasebuild device.builder.nut > dist/device.nut
```

## Pinout

J9.3 has 7-pin interface located at the top-left side under the fresh cofee cover:

(right-to-left)

1. -
2. +5V
3. -
4. RX
5. GND
6. TX
7. -

Connection is 5V TTL UART, so a [logic level converter](https://www.sparkfun.com/products/12009) is needed. 

## License

Do anything you want with this, at your own risk.
