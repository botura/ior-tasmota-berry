# Configuração usando a funçao nativa do Tasmota para as saídas (74x595) e usando Berry para ler as entradas e dar um toogle nas saídas


* Baixar o repositório do Tasmota
* Copiar o arquivo `user_config_override.h`
* Alterar para 16 o valor da constante `MAX_HUE_DEVICES` no arquivo `tasmota.h` para a Alexa enxergar as 16 saídas
* Compilar e gravar o firmware no esp32
* Configurar os pinos conforme o arquivo `Tasmota - Configurar Modelo.pdf`
* Habilitar `Hue Bridge multi device` para o Tasmota ser visto pela Alexa
* Copiar os arquivos `autoexec.be` e `ior-input.be` para o esp32 para as entradas funcionarem
