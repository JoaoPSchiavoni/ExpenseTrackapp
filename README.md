# Spendly App

Aplicativo Flutter multiplataforma de finanças pessoais que consome a API
[Expense Tracker](https://github.com/JoaoPSchiavoni/expenseTrackerBack). A
interface é responsiva e funciona em mobile, web e desktop.

## Recursos

- autenticação JWT, cadastro e modo demonstração;
- onboarding guiado e página pública sobre a arquitetura;
- temas claro e escuro com preferência persistida;
- dashboard com saldo, receitas, despesas e fluxo de caixa interativo;
- projeção de saldo, comparação entre períodos e saúde financeira;
- carteiras, categorias, transações, orçamentos e metas;
- recorrências e planejamento financeiro;
- importação de extratos CSV/OFX com preview;
- conversão de moedas por cotação pública;
- regras de categorização e detecção de assinaturas;
- alertas de orçamento, cobranças e vencimentos;
- relatório financeiro mensal em PDF.

## Tecnologias

- Flutter e Dart;
- Material 3;
- HTTP REST;
- armazenamento seguro do token;
- SharedPreferences para preferências locais;
- File Picker para importação e exportação de arquivos.

## Executar

```bash
flutter pub get
flutter run
```

Por padrão, o aplicativo utiliza o backend publicado na Render. Para apontar
para outro ambiente:

```bash
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

## Validar

```bash
flutter analyze
flutter test
```
