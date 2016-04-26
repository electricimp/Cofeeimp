# Coffeeimp

Impified _Jura IMPRESSA J9.3_. 

## Pinout

J9.3 has a 7-pin interface located at the top-left side under the fresh cofee cover:

(right-to-left)

1. -
2. +5V
3. -
4. RX
5. GND
6. TX
7. -

Connection is 5V TTL UART, so a [logic level converter](https://www.sparkfun.com/products/12009) is needed. 

## Building

```sh
npm i -g Builder

# device
pleasebuild device.builder.nut > device.nut

# agent
pleasebuild agent.builder.nut > agent.nut
```

## License

Do anything you want with this but at your own risk.

<br />

 _@author Mikhail Yurasov \<mikhail@electricimp.com\>_
