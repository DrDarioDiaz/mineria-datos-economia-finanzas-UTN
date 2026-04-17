# Carga de librerías
suppressPackageStartupMessages({
  library(tidyverse)
  library(naniar)
  library(VIM)
  library(mice)
  library(corrplot)
  library(gridExtra)
  library(pROC)
})

# Intentar cargar missForest (puede fallar si no se instala)
miss_forest_ok <- tryCatch({
  library(missForest)
  TRUE
}, error = function(e) {
  cat("ℹ️  missForest no disponible. Se usarán los otros métodos.\n")
  FALSE
})

# Configuración estética global
theme_set(theme_minimal(base_size = 12, base_family = "sans") +
            theme(plot.title = element_text(face = "bold", size = 14),
                  plot.subtitle = element_text(color = "gray40"),
                  legend.position = "bottom"))

# Paleta de colores del curso
col_good  <- "#2a9d8f"
col_bad   <- "#e76f51"
col_acc   <- "#f4a261"
palette_curso <- c("good" = col_good, "bad" = col_bad)

cat("\n╔══════════════════════════════════════════════════╗\n")
cat("║   Entorno R configurado correctamente            ║\n")
cat("╠══════════════════════════════════════════════════╣\n")
cat(sprintf("║   R          : %-37s║\n", R.version$version.string))
cat(sprintf("║   tidyverse  : %-37s║\n", packageVersion("tidyverse")))
cat(sprintf("║   mice       : %-37s║\n", packageVersion("mice")))
cat(sprintf("║   naniar     : %-37s║\n", packageVersion("naniar")))
cat(sprintf("║   VIM        : %-37s║\n", packageVersion("VIM")))
cat(sprintf("║   pROC       : %-37s║\n", packageVersion("pROC")))
cat("╚══════════════════════════════════════════════════╝\n")

# ══════════════════════════════════════════════════════════════
# 2. CARGA DEL DATASET
# ══════════════════════════════════════════════════════════════

# Descarga desde OpenML (alternativa: cargar desde Drive)
url_data <- "https://www.openml.org/data/get_csv/31/dataset_31_credit-g.arff"

df_original <- tryCatch({
  df <- read_csv(url_data, show_col_types = FALSE)
  cat("✅ Dataset descargado desde OpenML\n")
  df
}, error = function(e) {
  cat("ℹ️  OpenML no accesible. Cargando desde Drive...\n")
  read_csv("/content/drive/MyDrive/datasets/german_credit.csv", show_col_types = FALSE)
})

# Variables numéricas clave
num_vars <- c("duration", "credit_amount", "installment_commitment",
              "residence_since", "age", "existing_credits", "num_dependents")

cat(sprintf("\n  Dimensiones: %s filas × %d columnas\n",
            format(nrow(df_original), big.mark = ","), ncol(df_original)))
cat(sprintf("  Valores faltantes totales: %d\n", sum(is.na(df_original))))
cat(sprintf("\n  Estadísticos de credit_amount (ground truth):\n"))
cat(sprintf("    Media   = %.2f\n", mean(df_original$credit_amount)))
cat(sprintf("    Mediana = %.2f\n", median(df_original$credit_amount)))
cat(sprintf("    Desvío  = %.2f\n", sd(df_original$credit_amount)))

# ══════════════════════════════════════════════════════════════
# 3. SIMULACIÓN DE MCAR, MAR, MNAR
# ══════════════════════════════════════════════════════════════

set.seed(42)
n <- nrow(df_original)
prop_miss <- 0.20

# ── 3.1 MCAR: ausencia puramente aleatoria ──
mask_mcar <- runif(n) < prop_miss

# ── 3.2 MAR: ausencia depende de 'age' (variable observada) ──
# Jóvenes tienen mayor probabilidad de no reportar el monto
prob_mar <- 1 / (1 + exp(0.08 * (df_original$age - 28)))
prob_mar <- prob_mar / mean(prob_mar) * prop_miss
prob_mar <- pmin(pmax(prob_mar, 0.01), 0.95)
mask_mar <- runif(n) < prob_mar

# ── 3.3 MNAR: ausencia depende del propio credit_amount ──
# Montos altos tienen mayor probabilidad de no ser reportados
ca <- df_original$credit_amount
prob_mnar <- 1 / (1 + exp(-0.0008 * (ca - quantile(ca, 0.7))))
prob_mnar <- prob_mnar / mean(prob_mnar) * prop_miss
prob_mnar <- pmin(pmax(prob_mnar, 0.01), 0.95)
mask_mnar <- runif(n) < prob_mnar

# Crear DataFrames con faltantes
df_mcar <- df_original; df_mcar$credit_amount[mask_mcar] <- NA
df_mar  <- df_original; df_mar$credit_amount[mask_mar]   <- NA
df_mnar <- df_original; df_mnar$credit_amount[mask_mnar] <- NA

cat("═══════════════════════════════════════════════════════════\n")
cat("RESUMEN DE FALTANTES SIMULADOS EN credit_amount\n")
cat("═══════════════════════════════════════════════════════════\n")

mecanismos <- list(
  list(nombre = "MCAR", mascara = mask_mcar),
  list(nombre = "MAR",  mascara = mask_mar),
  list(nombre = "MNAR", mascara = mask_mnar)
)

for (m in mecanismos) {
  mk <- m$mascara
  n_miss <- sum(mk)
  m_obs <- mean(df_original$credit_amount[!mk])
  m_mis <- mean(df_original$credit_amount[mk])
  dif <- abs(m_obs - m_mis)
  flag <- ifelse(dif > 200, "  ← sesgo!", "  ← sin sesgo")
  
  cat(sprintf("\n  %s:\n", m$nombre))
  cat(sprintf("    Faltantes: %d (%.1f%%)\n", n_miss, n_miss / n * 100))
  cat(sprintf("    Media de los OBSERVADOS:         %.0f\n", m_obs))
  cat(sprintf("    Media de los FALTANTES (verdad):  %.0f\n", m_mis))
  cat(sprintf("    Diferencia:                       %.0f%s\n", dif, flag))
}

# ══════════════════════════════════════════════════════════════
# 4.1 VISUALIZACIÓN: vis_miss (patrón global)
# ══════════════════════════════════════════════════════════════

options(repr.plot.width = 14, repr.plot.height = 5)

# Creamos un DataFrame con faltantes en múltiples variables para visualizar
df_demo <- df_mar[num_vars]
# Agregamos faltantes en 'age' bajo MAR (depende de duration) para enriquecer
mask_age <- runif(n) < (0.15 * as.integer(df_original$duration > 24) + 0.05)
df_demo$age[mask_age] <- NA

p_vismiss <- vis_miss(df_demo, sort_miss = TRUE) +
  ggtitle("Patrón de ausencia (MAR simulado)") +
  theme(plot.title = element_text(face = "bold", size = 13))

print(p_vismiss)

# ══════════════════════════════════════════════════════════════
# 4.2 FALTANTES POR VARIABLE
# ══════════════════════════════════════════════════════════════

options(repr.plot.width = 10, repr.plot.height = 5)

p_missvar <- gg_miss_var(df_demo) +
  ggtitle("Cantidad de valores faltantes por variable") +
  theme(plot.title = element_text(face = "bold", size = 13))

print(p_missvar)

# ══════════════════════════════════════════════════════════════
# 4.3 SHADOW PLOT: distribución condicional a la ausencia
# ══════════════════════════════════════════════════════════════

# ¿La distribución de 'age' difiere entre quienes reportan credit_amount y quienes no?
options(repr.plot.width = 13, repr.plot.height = 5)

df_shadow <- df_mar %>%
  select(all_of(num_vars)) %>%
  bind_shadow() %>%
  mutate(credit_amount_NA = factor(
    credit_amount_NA,
    levels = c("!NA", "NA"),
    labels = c("Observado", "Faltante")
  ))

p_shadow <- ggplot(df_shadow, aes(x = age, fill = credit_amount_NA)) +
  geom_density(alpha = 0.6, color = "white", linewidth = 0.3) +
  scale_fill_manual(values = c(col_good, col_bad)) +
  labs(
    title = "Distribución de age según presencia/ausencia de credit_amount",
    subtitle = "Si las densidades difieren → la ausencia depende de age → mecanismo MAR",
    x = "Edad del solicitante", y = "Densidad",
    fill = "credit_amount"
  )

print(p_shadow)

# ══════════════════════════════════════════════════════════════
# 5.1 REGRESIÓN LOGÍSTICA DEL INDICADOR DE AUSENCIA
# ══════════════════════════════════════════════════════════════

cat("═══════════════════════════════════════════════════════════\n")
cat("DIAGNÓSTICO: REGRESIÓN LOGÍSTICA DE R (indicador de ausencia)\n")
cat("═══════════════════════════════════════════════════════════\n")

# Variables predictoras para el diagnóstico (excluimos credit_amount)
X_diag <- df_original %>%
  select(duration, installment_commitment, residence_since,
         age, existing_credits, num_dependents)

for (m in mecanismos) {
  nm <- m$nombre; mk <- m$mascara
  
  # Crear el DataFrame para la regresión
  df_lr <- X_diag %>% mutate(R_missing = as.integer(mk))
  
  # Ajustar regresión logística
  fit <- glm(R_missing ~ ., data = df_lr, family = binomial)
  probs <- predict(fit, type = "response")
  
  # Calcular AUC-ROC con pROC
  roc_obj <- roc(df_lr$R_missing, probs, quiet = TRUE)
  auc_val <- as.numeric(auc(roc_obj))
  
  cat(sprintf("\n  %s:", nm))
  cat(sprintf("  AUC-ROC = %.4f", auc_val))
  
  if (auc_val < 0.55) {
    cat("  →  Ausencia NO predecible → compatible con MCAR ✅")
  } else if (auc_val < 0.65) {
    cat("  →  Predicción débil → posible MAR leve")
  } else {
    cat("  →  Ausencia PREDECIBLE → MAR confirmado ⚠️")
  }
  
  # Coeficientes más relevantes
  coefs <- abs(coef(fit)[-1])  # excluir intercept
  top_var <- names(sort(coefs, decreasing = TRUE))[1]
  cat(sprintf("\n    Variable más predictiva: '%s' (|β| = %.4f)\n", top_var, max(coefs)))
}

# ══════════════════════════════════════════════════════════════
# 5.2 TEST DE LITTLE PARA MCAR
# ══════════════════════════════════════════════════════════════

cat("\n═══════════════════════════════════════════════════════════\n")
cat("TEST DE LITTLE (H₀: los datos son MCAR)\n")
cat("═══════════════════════════════════════════════════════════\n")

datasets_test <- list(
  list(nombre = "MCAR", datos = df_mcar),
  list(nombre = "MAR",  datos = df_mar),
  list(nombre = "MNAR", datos = df_mnar)
)

for (d in datasets_test) {
  tryCatch({
    test_result <- mcar_test(d$datos[num_vars])
    cat(sprintf("\n  %s:  χ² = %.2f,  df = %d,  p-valor = %.4f",
                d$nombre, test_result$statistic, test_result$df, test_result$p.value))
    if (test_result$p.value > 0.05) {
      cat("  →  No rechaza MCAR ✅")
    } else {
      cat("  →  RECHAZA MCAR → MAR o MNAR ⚠️")
    }
  }, error = function(e) {
    cat(sprintf("\n  %s:  Test no ejecutable (%s)", d$nombre, conditionMessage(e)))
  })
}
cat("\n")

# ══════════════════════════════════════════════════════════════
# 5.3 CORRELACIÓN POINT-BISERIAL
# ══════════════════════════════════════════════════════════════

cat("\n═══════════════════════════════════════════════════════════\n")
cat("CORRELACIÓN POINT-BISERIAL: R(credit_amount) vs. variables\n")
cat("═══════════════════════════════════════════════════════════\n")

vars_corr <- c("duration", "age", "installment_commitment", "residence_since")

for (m in mecanismos) {
  cat(sprintf("\n  %s:\n", m$nombre))
  r_indicator <- as.integer(m$mascara)
  
  for (v in vars_corr) {
    test <- cor.test(r_indicator, df_original[[v]])
    r_val <- test$estimate
    p_val <- test$p.value
    sig <- ifelse(p_val < 0.001, "***",
                  ifelse(p_val < 0.01, "**",
                         ifelse(p_val < 0.05, "*", "ns")))
    cat(sprintf("    vs. %-28s r_pb = %+.4f  (p = %.4f) %s\n", v, r_val, p_val, sig))
  }
}

# ══════════════════════════════════════════════════════════════
# 6. IMPUTACIÓN — 5 ESTRATEGIAS CON mice Y COMPARACIÓN
# ══════════════════════════════════════════════════════════════

# Función de evaluación contra ground truth
evaluate_imp <- function(mascara, verdaderos, imputados, metodo) {
  tv <- verdaderos[mascara]
  iv <- imputados[mascara]
  mae  <- mean(abs(tv - iv))
  rmse <- sqrt(mean((tv - iv)^2))
  sesgo <- mean(iv) - mean(tv)
  data.frame(
    Metodo     = metodo,
    MAE        = round(mae, 1),
    RMSE       = round(rmse, 1),
    Media_imp  = round(mean(iv), 1),
    Media_real = round(mean(tv), 1),
    Sesgo      = round(sesgo, 1),
    Sesgo_pct  = round(sesgo / mean(tv) * 100, 1),
    stringsAsFactors = FALSE
  )
}

cat("═══════════════════════════════════════════════════════════\n")
cat("COMPARACIÓN DE ESTRATEGIAS DE IMPUTACIÓN\n")
cat("═══════════════════════════════════════════════════════════\n")

true_ca <- df_original$credit_amount

datos_na <- list(
  list(nombre = "MCAR", df = df_mcar, mascara = mask_mcar),
  list(nombre = "MAR",  df = df_mar,  mascara = mask_mar),
  list(nombre = "MNAR", df = df_mnar, mascara = mask_mnar)
)

for (d in datos_na) {
  X_na <- d$df[num_vars]
  mk   <- d$mascara
  resultados <- list()
  
  # M1: Listwise deletion (media de los casos completos)
  mean_cc <- mean(X_na$credit_amount, na.rm = TRUE)
  imp_lw  <- X_na$credit_amount
  imp_lw[mk] <- mean_cc
  resultados[[1]] <- evaluate_imp(mk, true_ca, imp_lw, "Listwise (media CC)")
  
  # M2: Mediana
  med_val <- median(X_na$credit_amount, na.rm = TRUE)
  imp_med <- X_na$credit_amount
  imp_med[mk] <- med_val
  resultados[[2]] <- evaluate_imp(mk, true_ca, imp_med, "Mediana")
  
  # M3: mice — Predictive Mean Matching (PMM)
  imp_pmm <- mice(X_na, m = 1, method = "pmm", maxit = 5, printFlag = FALSE, seed = 42)
  X_pmm   <- complete(imp_pmm)
  resultados[[3]] <- evaluate_imp(mk, true_ca, X_pmm$credit_amount, "mice (PMM)")
  
  # M4: mice — CART (árboles de decisión)
  imp_cart <- mice(X_na, m = 1, method = "cart", maxit = 5, printFlag = FALSE, seed = 42)
  X_cart   <- complete(imp_cart)
  resultados[[4]] <- evaluate_imp(mk, true_ca, X_cart$credit_amount, "mice (CART)")
  
  # M5: mice — Regresión lineal con ruido (norm)
  imp_norm <- mice(X_na, m = 1, method = "norm", maxit = 5, printFlag = FALSE, seed = 42)
  X_norm   <- complete(imp_norm)
  resultados[[5]] <- evaluate_imp(mk, true_ca, X_norm$credit_amount, "mice (norm)")
  
  cat(sprintf("\n═══════════════════════════════════════════════════════════\n"))
  cat(sprintf("  MECANISMO: %s\n", d$nombre))
  cat(sprintf("═══════════════════════════════════════════════════════════\n\n"))
  res_df <- bind_rows(resultados)
  print(as.data.frame(res_df), row.names = FALSE)
}


# ══════════════════════════════════════════════════════════════
# 7. DISTRIBUCIONES POST-IMPUTACIÓN
# ══════════════════════════════════════════════════════════════

options(repr.plot.width = 17, repr.plot.height = 5.5)

plots_dist <- list()

for (d in datos_na) {
  X_na <- d$df[num_vars]
  
  # mice PMM
  imp <- mice(X_na, m = 1, method = "pmm", maxit = 5, printFlag = FALSE, seed = 42)
  X_imp <- complete(imp)
  
  # Media simple
  media_val <- mean(X_na$credit_amount, na.rm = TRUE)
  ca_media <- X_na$credit_amount
  ca_media[is.na(ca_media)] <- media_val
  
  # Combinar para ggplot
  df_plot <- bind_rows(
    tibble(credit_amount = df_original$credit_amount, Fuente = "Ground truth"),
    tibble(credit_amount = X_imp$credit_amount,       Fuente = "mice (PMM)"),
    tibble(credit_amount = ca_media,                   Fuente = "Media")
  ) %>%
    mutate(Fuente = factor(Fuente, levels = c("Ground truth", "mice (PMM)", "Media")))
  
  p <- ggplot(df_plot, aes(x = credit_amount, fill = Fuente)) +
    geom_density(alpha = 0.45, color = "white", linewidth = 0.3) +
    scale_fill_manual(values = c("Ground truth" = "gray50",
                                 "mice (PMM)"  = col_good,
                                 "Media"        = col_bad)) +
    labs(title = d$nombre, x = "credit_amount", y = "Densidad") +
    theme(legend.position = "bottom", legend.title = element_blank(),
          plot.title = element_text(hjust = 0.5))
  
  plots_dist[[d$nombre]] <- p
}

grid.arrange(
  grobs = plots_dist, ncol = 3,
  top = grid::textGrob(
    "Distribución post-imputación vs. ground truth por mecanismo",
    gp = grid::gpar(fontface = "bold", fontsize = 13)
  )
)

# ══════════════════════════════════════════════════════════════
# 8. VISUALIZACIÓN CON VIM: matrixplot y marginplot
# ══════════════════════════════════════════════════════════════

options(repr.plot.width = 13, repr.plot.height = 6)

# marginplot: distribución bivariada resaltando los faltantes
marginplot(df_mar[, c("credit_amount", "age")],
           col = c(col_good, col_bad, col_acc),
           main = "Marginplot: credit_amount vs. age (MAR)",
           pch = 19, cex = 0.6)



