# Política de segurança

**Português** · [English](#english)

## Versões com suporte

Só a versão mais recente do Orbit recebe correções de segurança. Atualize rodando de novo o comando de instalação.

## Como relatar uma vulnerabilidade

**Não abra uma issue pública.** Use o relato privado do GitHub:
[Security → Report a vulnerability](https://github.com/webdevpls/orbit/security/advisories/new).

Inclua a versão do Orbit e do macOS, o passo a passo para reproduzir e o impacto que você observou. Você recebe uma resposta em até 7 dias, e a correção sai em uma nova versão, com crédito a você se quiser.

## O que o Orbit faz e não faz

- Usa a permissão de **Acessibilidade** para observar os botões do mouse. Teclas só são lidas **enquanto o anel está aberto** (Esc, Return, setas, 1–8); fora disso passam direto, sem serem inspecionadas.
- **Nunca grava, salva ou envia** cliques, teclas ou posições do cursor.
- A única conexão de rede baixa o ícone dos sites que você adiciona ao anel: do próprio site ou, se ele bloquear, do serviço de ícones do DuckDuckGo (que recebe só o domínio). O `install.sh` baixa a release do GitHub.
- Guarda as preferências só no seu Mac (`~/Library/Preferences/io.github.orbit-ring.plist`).

## Verificando um download

Cada release publica o arquivo `SHA256SUMS.txt`. O `install.sh` confere automaticamente a soma SHA-256 e a assinatura do app antes de instalar. Para conferir manualmente:

```sh
shasum -a 256 Orbit.dmg Orbit.zip
codesign --verify --deep --strict --verbose=2 /Applications/Orbit.app
```

---

## English

Only the latest release receives security fixes. **Don't open a public issue** for vulnerabilities: report them privately through
[Security → Report a vulnerability](https://github.com/webdevpls/orbit/security/advisories/new). You'll get a reply within 7 days.

Orbit uses Accessibility access to watch mouse buttons; keys are only read while the ring is open. It never records or uploads input. Its only network access fetches icons for websites you add. Each release ships `SHA256SUMS.txt`; `install.sh` verifies the checksum and the app signature before installing.
