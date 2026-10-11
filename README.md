# FAUNA — La Guerra de las Dos Naciones

**FAUNA** es un juego táctico 3D en tiempo real pensado para pantallas táctiles,
desarrollado con **Godot 4**. Enfrenta a dos naciones — **Castor** y **Oso** — en
escenarios abiertos con un río y un puente que dividen el campo de batalla.

El objetivo del proyecto es una experiencia de estrategia directa: seleccionar
unidades, dar órdenes de movimiento y coordinar pequeñas formaciones con controles
de toque simples e intuitivos.

## Concepto

- **Dos naciones:** Castor (oeste) y Oso (este), separadas por un río y un puente.
- **Unidades sobre un terreno 3D** con cámara táctica (paneo, zoom y rotación).
- **Selección táctil** de una o varias unidades, con anillos de selección, barras
  de vida y marcadores de destino.
- **Órdenes de movimiento** por toque y **formaciones de grupo** cuando hay varias
  unidades seleccionadas.
- **Minimapa** y panel de mando (incluye la acción **DETENER**).

## Unidades

**Nación Castor**
- **Castor CMD** — vehículo de mando / reconocimiento (rol de apoyo).
- **Castor LT** — tanque.
- **Scout** — reconocimiento, anfibio.

**Nación Oso**
- **Oso 413** — blindado de ruedas.
- **Oso Scout** — reconocimiento, anfibio (equivalente al Scout de Castor).
- **Oso 47** — tanque de orugas (equivalente al Castor LT).

Cada unidad define sus estadísticas (coste, vida, velocidad, visión, rango, daño,
recarga, blindaje, combustible, etc.) en recursos `UnitStats` dentro de
`resources/units/`.

## Controles

- **Toque en una unidad:** la selecciona.
- **Toque en otra unidad:** cambia la selección.
- **Toque en la unidad ya seleccionada:** la deselecciona.
- **Toque en terreno con selección:** ordena movimiento al punto.
- **Doble toque en una unidad:** selección múltiple de las unidades cercanas (5 m)
  y activación del panel de grupo.
- **Arrastrar sobre el terreno:** selección por rectángulo.
- **Mantener pulsado en terreno vacío:** deselecciona todo.
- **Dos dedos:** zoom y rotación de la cámara.
- **DETENER:** cancela el movimiento de las unidades seleccionadas.

## Requisitos

- **Godot 4.7** o superior (el proyecto está configurado con el renderizador
  *Mobile* y el motor de física *Jolt*).
- Recomendado para ejecutar en Android; el proyecto también abre en escritorio.

## Cómo abrir el proyecto con Godot

1. Descarga e instala **Godot 4.7+** desde <https://godotengine.org/download>.
2. Abre el **Project Manager** de Godot.
3. Pulsa **Import** y selecciona el archivo `project.godot` de este repositorio.
4. Confirma la importación y abre el proyecto.
5. Ejecuta con **F5** (o el botón *Play*). La escena principal es
   `res://scenes/main.tscn`.

En Android también puedes usar el editor de Godot para importar y ejecutar el
proyecto directamente en el dispositivo.

## Estructura del proyecto

```
fauna/
├── project.godot          # Configuración del proyecto Godot
├── icon.svg               # Icono
├── resources/units/       # Estadísticas de unidades (UnitStats .tres)
├── scenes/                # Escenas (.tscn): mapa, unidades, UI, cámara, marcadores
└── scripts/               # Código GDScript
    ├── camera/            # Cámara táctica
    ├── common/            # Utilidades (MeshFactory para geometría 3D)
    ├── controls/          # Entrada táctil
    ├── game/              # Lógica principal (selección, órdenes, formación)
    ├── map/               # Configuración del mapa y navegación (NavGrid)
    ├── markers/           # Marcadores de orden de movimiento
    ├── ui/                # HUD: paneles, minimapa, caja de selección
    └── units/             # Unidades y estadísticas
```

> La carpeta `.godot/` es caché generada por el editor y no forma parte del
> código fuente del proyecto (está excluida por `.gitignore`).

## Estado

Proyecto en desarrollo. El modelo visual de las unidades es completamente
procedural (construido por código con geometría 3D), sin depender de modelos o
texturas externas.

## Licencia

Sin licencia definida por el momento. Todos los derechos reservados salvo que se
indique lo contrario.
