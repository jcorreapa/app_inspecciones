import 'dart:io';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/material.dart';
import 'package:inspecciones/core/enums.dart';
import 'package:inspecciones/infrastructure/moor_database.dart';
import 'package:inspecciones/infrastructure/repositories/cuestionarios_repository.dart';
import 'package:inspecciones/injection.dart';
import 'package:inspecciones/mvvc/common_widgets.dart';
import 'package:inspecciones/mvvc/creacion_controls.dart';
import 'package:inspecciones/mvvc/creacion_cuadricula_card.dart';
import 'package:inspecciones/mvvc/creacion_form_controller.dart';
import 'package:inspecciones/mvvc/creacion_numerica_card.dart';
import 'package:inspecciones/presentation/pages/ayuda_screen.dart';
import 'package:provider/provider.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:reactive_multi_image_picker/reactive_multi_image_picker.dart';
import 'package:simple_tooltip/simple_tooltip.dart';

/// Definición de los Widgets usados en los bloques de la creación de cuestionarios.
///
/// Los formGroups se definen en [creacion_controls.dart] y son los encargados de hacer las validaciones.

/// Cuando en el formulario se presiona añadir titulo, este es el widget que se muestra
class CreadorTituloCard extends StatelessWidget {
  final CreadorTituloController controller;

  const CreadorTituloCard({Key? key, required this.controller})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Card(
      //TODO: destacar mejor los titulos
      shape: RoundedRectangleBorder(
          side:
              BorderSide(color: Theme.of(context).backgroundColor, width: 2.0),
          borderRadius: BorderRadius.circular(4.0)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            ReactiveTextField(
              style: Theme.of(context).textTheme.headline5,
              formControl: controller.tituloControl,
              validationMessages: (control) =>
                  {ValidationMessage.required: 'El titulo no debe ser vacío'},
              decoration: const InputDecoration(
                labelText: 'Titulo de sección',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 10),
            ReactiveTextField(
              style: Theme.of(context).textTheme.bodyText2,
              formControl: controller.descripcionControl,
              decoration: const InputDecoration(
                labelText: 'Descripción',
              ),
              keyboardType: TextInputType.multiline,
              minLines: 1,
              maxLines: 50,
              textCapitalization: TextCapitalization.sentences,
            ),

            /// Row con widgets que permiten añadir o pegar otro bloque debajo del actual.
            BotonesDeBloque(controllerActual: controller),
          ],
        ),
      ),
    );
  }
}

//TODO: Unificar las cosas en común de los dos tipos de pregunta: las de seleccion y la numéricas.
/// Widget usado para la creación de preguntas numericas

class CreadorNumericaCard extends StatelessWidget {
  final CreadorPreguntaNumericaController preguntaController;

  const CreadorNumericaCard({Key? key, required this.preguntaController})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PreguntaCard(
        titulo: 'Pregunta numérica',
        child: Column(
          children: [
            /// Intento de unificar los widgets de cada pregunta
            /// Para poder hacer la unificacion exitosa hay que crear una
            /// interfaz o clase padre que implementen todos los tipos de pregunta
            TipoPreguntaCard(preguntaController: preguntaController),
            const SizedBox(height: 20),

            /// Widget para añadir los rangos y su respectiva criticidad
            CriticidadCard(preguntaController: preguntaController),
            const SizedBox(height: 20),

            /// Row con widgets que permiten añadir o pegar otro bloque debajo del actual.
            BotonesDeBloque(controllerActual: preguntaController),
          ],
        ));
  }
}

/// Widget  usado en la creación de preguntas de selección
class CreadorSeleccionSimpleCard extends StatelessWidget {
  /// Validaciones y métodos utiles
  final CreadorPreguntaController controller;

  const CreadorSeleccionSimpleCard({Key? key, required this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    /// Se accede a este provider del formulario base de creación para poder cargar los sistemas
    final formController = context.watch<CreacionFormController>();

    /// Como es de selección, se asegura que los unicos tipos de pregunta que pueda seleccionar el creador
    /// sean de unica o multiple respuesta
    /// TODO: reestructurar estos estados
    final List<TipoDePregunta> itemsTipoPregunta = controller.parteDeCuadricula
        ? [
            TipoDePregunta.parteDeCuadriculaUnica,
            TipoDePregunta.parteDeCuadriculaMultiple
          ]
        : [TipoDePregunta.unicaRespuesta, TipoDePregunta.multipleRespuesta];
    return PreguntaCard(
      titulo: 'Pregunta de selección',
      child: Column(
        children: [
          ReactiveTextField(
            formControl: controller.tituloControl,
            validationMessages: (control) =>
                {ValidationMessage.required: 'El titulo no debe estar vacío'},
            decoration: const InputDecoration(
              labelText: 'Título',
            ),
            keyboardType: TextInputType.multiline,
            minLines: 1,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 10),
          ReactiveTextField(
            formControl: controller.descripcionControl,
            decoration: const InputDecoration(
              labelText: 'Descripción',
            ),
            keyboardType: TextInputType.multiline,
            minLines: 1,
            maxLines: 50,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 10),

          /// Se puede elegir a que sistema está asociado la pregunta, dependiendo de ese sistema elegido, se cargan los subsistemas
          ReactiveDropdownField<Sistema?>(
            formControl: controller.sistemaControl,
            items: formController.todosLosSistemas
                .map((e) => DropdownMenuItem<Sistema>(
                      value: e,
                      child: Text(e.nombre),
                    ))
                .toList(),
            validationMessages: (control) =>
                {ValidationMessage.required: 'Seleccione el sistema'},
            decoration: const InputDecoration(
              labelText: 'Sistema',
            ),
          ),

          const SizedBox(height: 10),
          ValueListenableBuilder<List<SubSistema>>(
              valueListenable: controller.subSistemasDisponibles,
              builder: (context, value, child) {
                return ReactiveDropdownField<SubSistema?>(
                  formControl: controller.subSistemaControl,
                  validationMessages: (control) =>
                      {ValidationMessage.required: 'Seleccione el subsistema'},
                  items: value
                      .map((e) => DropdownMenuItem<SubSistema>(
                            value: e,
                            child: Text(e.nombre),
                          ))
                      .toList(),
                  decoration: const InputDecoration(
                    labelText: 'Subsistema',
                  ),
                  onTap: () {
                    FocusScope.of(context)
                        .unfocus(); // para que no salte el teclado si tenia un textfield seleccionado
                  },
                );
              }),
          const SizedBox(height: 5),
          const Divider(height: 15, color: Colors.black),
          Row(
            children: [
              const Expanded(
                flex: 3,
                child: Text(
                  'Posición',
                  textAlign: TextAlign.start,
                ),
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const Dialog(child: AyudaPage()),
                    );
                  },
                  child: const Text(
                    '¿Necesitas ayuda?',
                    textAlign: TextAlign.end,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 5),
          ReactiveDropdownField<String?>(
            formControl: controller.ejeControl,
            validationMessages: (control) =>
                {ValidationMessage.required: 'Este valor es requerido'},
            items: formController.ejes
                .map((e) => DropdownMenuItem<String>(
                      value: e,
                      child: Text(e),
                    ))
                .toList(),
            decoration: const InputDecoration(
              labelText: 'Posición Y',
            ),
            onTap: () {
              FocusScope.of(context)
                  .unfocus(); // para que no salte el teclado si tenia un textfield seleccionado
            },
          ),
          const SizedBox(height: 10),
          ReactiveDropdownField<String?>(
            formControl: controller.ladoControl,
            validationMessages: (control) =>
                {ValidationMessage.required: 'Este valor es requerido'},
            items: formController.lados
                .map((e) => DropdownMenuItem<String>(
                      value: e,
                      child: Text(e),
                    ))
                .toList(),
            decoration: const InputDecoration(
              labelText: 'Posición X',
            ),
            onTap: () {
              FocusScope.of(context)
                  .unfocus(); // para que no salte el teclado si tenia un textfield seleccionado
            },
          ),
          const SizedBox(height: 10),
          ReactiveDropdownField<String?>(
            formControl: controller.posicionZControl,
            validationMessages: (control) =>
                {ValidationMessage.required: 'Este valor es requerido'},
            items: formController.posZ
                .map((e) => DropdownMenuItem<String>(
                      value: e,
                      child: Text(e),
                    ))
                .toList(),
            decoration: const InputDecoration(
              labelText: 'Posición Z',
            ),
            onTap: () {
              FocusScope.of(context)
                  .unfocus(); // para que no salte el teclado si tenia un textfield seleccionado
            },
          ),
          const SizedBox(height: 10),

          InputDecorator(
            decoration: const InputDecoration(
                labelText: 'Criticidad de la pregunta', filled: false),
            child: ReactiveSlider(
              formControl: controller.criticidadControl,
              max: 4,
              divisions: 4,
              labelBuilder: (v) => v.round().toString(),
              activeColor: Colors.red,
            ),
          ),
          ReactiveMultiImagePicker<String, File>(
            formControl: controller.fotosGuiaControl,
            maxImages: 3,
            decoration: const InputDecoration(
              labelText: 'Fotos guía',
            ),
          ),
          const SizedBox(height: 10),
          ReactiveDropdownField<TipoDePregunta>(
            formControl: controller.tipoDePreguntaControl,
            validationMessages: (control) =>
                {ValidationMessage.required: 'Seleccione el tipo de pregunta'},
            items: itemsTipoPregunta
                .map((e) => DropdownMenuItem<TipoDePregunta>(
                      value: e,
                      child: Text(
                          EnumToString.convertToString(e, camelCase: true)),
                    ))
                .toList(),
            decoration: const InputDecoration(
              labelText: 'Tipo de pregunta',
            ),
            onTap: () {
              FocusScope.of(context)
                  .unfocus(); // para que no salte el teclado si tenia un textfield seleccionado
            },
          ),
          const SizedBox(height: 10),

          /// Este widget ([CreadorSeleccionSimpleCard]) también es usado cuando se añade una pregunta (fila) a una cuadricula
          /// para añadir los detalles (fotosGuia, descripcion...) por lo cual hay que hacer está validación
          /// para que al ser parte de cuadricula no de la opción de añadir respuestas o más bloques.
          if (!controller.parteDeCuadricula)
            Column(
              children: [
                WidgetRespuestas(controlPregunta: controller),
                BotonesDeBloque(controllerActual: controller),
              ],
            )
        ],
      ),
    );
  }
}

/// Widget usado para añadir las opciones de respuesta a las preguntas de cuadricula o de selección
class WidgetRespuestas extends StatelessWidget {
  const WidgetRespuestas({
    Key? key,
    required this.controlPregunta,
  }) : super(key: key);

  final ConRespuestas controlPregunta;

  @override
  Widget build(BuildContext context) {
    /// Como las respuestas se van añadiendo dinámicamente, este  ReactiveValueListenableBuilder escucha, por decirlo asi,
    /// el length del control respuestas [formControl], así cada que se va añadiendo una opción, se muestra el nuevo widget en la UI
    return ReactiveValueListenableBuilder(
        formControl: controlPregunta.respuestasControl,
        builder: (context, formControl, child) {
          final controlesRespuestas = controlPregunta.controllersRespuestas;
          return Column(
            children: [
              Text(
                'Respuestas',
                style: Theme.of(context).textTheme.headline6,
              ),

              /// Si no se ha añadido ninguna opción de respuesta
              if (formControl.invalid &&
                  formControl.errors.entries.first.key == 'minLength')
                const Text(
                  'Agregue una opción de respuesta',
                  style: TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 10),
              if (controlesRespuestas.isNotEmpty)
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controlesRespuestas.length,
                  itemBuilder: (context, i) {
                    final controlRespuesta = controlesRespuestas[i];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      //Las keys sirven para que flutter maneje correctamente los widgets de la lista
                      key: ValueKey(controlRespuesta),
                      children: [
                        Row(
                          children: [
                            ValueListenableBuilder<bool>(
                              valueListenable: controlRespuesta.mostrarToolTip,
                              builder: (BuildContext context, mostrarToolTip,
                                  child) {
                                return SimpleTooltip(
                                  show: mostrarToolTip,
                                  tooltipDirection: TooltipDirection.right,
                                  content: Text(
                                    "Seleccione si el inspector puede asignar una criticidad propia al elegir esta respuesta",
                                    style:
                                        Theme.of(context).textTheme.subtitle2,
                                  ),
                                  ballonPadding: const EdgeInsets.all(2),
                                  borderColor: Theme.of(context).primaryColor,
                                  borderWidth: 0,
                                  child: IconButton(
                                      iconSize: 20,
                                      icon: const Icon(
                                        Icons.info,
                                      ),
                                      onPressed: () => controlRespuesta
                                              .mostrarToolTip.value =
                                          !controlRespuesta
                                              .mostrarToolTip.value),
                                );
                              },
                            ),
                            Flexible(
                              child: ReactiveCheckboxListTile(
                                formControl:
                                    controlRespuesta.calificableControl,
                                title: const Text('Calificable'),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: ReactiveTextField(
                                formControl: controlRespuesta.textoControl,
                                validationMessages: (control) => {
                                  ValidationMessage.required:
                                      'Este valor es requerido'
                                },
                                decoration: const InputDecoration(
                                  labelText: 'Respuesta',
                                ),
                                keyboardType: TextInputType.multiline,
                                maxLines: 3,
                                minLines: 1,
                                textCapitalization:
                                    TextCapitalization.sentences,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              tooltip: 'Borrar respuesta',
                              onPressed: () => controlPregunta
                                  .borrarRespuesta(controlRespuesta),
                            ),
                          ],
                        ),
                        ReactiveSlider(
                          formControl: controlRespuesta.criticidadControl,
                          max: 4,
                          divisions: 4,
                          labelBuilder: (v) => v.round().toString(),
                          activeColor: Colors.red,
                        ),
                      ],
                    );
                  },
                  separatorBuilder: (BuildContext context, int index) {
                    return const Divider();
                  },
                ),

              /// Se muestra este botón por defecto, al presionarlo se añade un
              ///  nuevo control al FormArray [controlesRespuestas]
              OutlinedButton(
                onPressed: () => controlPregunta.agregarRespuesta(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.add),
                    Text("Agregar respuesta"),
                  ],
                ),
              ),
            ],
          );
        });
  }
}

/// Reúne todas las acciones comunes a todos los bloques, incluye agregar nuevo tipo de pregunta, agregar titulo, copiar y pegar bloque
class BotonesDeBloque extends StatelessWidget {
  const BotonesDeBloque({Key? key, required this.controllerActual})
      : super(key: key);

  final CreacionController controllerActual;

  @override
  Widget build(BuildContext context) {
    final formController = context.read<CreacionFormController>();
    final animatedList = AnimatedList.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        /// Añade control [CreadorPreguntaFormGroup()] al control 'bloques' del cuestionario y muestra widget [CreadorSeleccionSimpleCard]
        IconButton(
          icon: const Icon(Icons.add_circle),
          tooltip: 'Pregunta de selección',
          onPressed: () => agregarBloque(
            formController,
            animatedList,
            CreadorPreguntaController(
                getIt<CuestionariosRepository>(), null, null),
          ),
        ),

        /// Añade control [CreadorPreguntaNumericaFormGroup()] al control 'bloques' del cuestionario y muestra widget [CreadorNumericaCard]
        IconButton(
          icon: const Icon(Icons.calculate),
          tooltip: 'Pregunta Númerica',
          onPressed: () => agregarBloque(
            formController,
            animatedList,
            CreadorPreguntaCuadriculaController(
                getIt<CuestionariosRepository>(), null, null),
          ),
        ),

        /// Añade control [CreadorPreguntaCuadriculaFormGroup()] al control 'bloques' del cuestionario y muestra widget [CreadorCuadriculaCard]
        IconButton(
          icon: const Icon(Icons.view_module),
          tooltip: 'Agregar cuadricula',
          onPressed: () => agregarBloque(
            formController,
            animatedList,
            CreadorPreguntaNumericaController(
                getIt<CuestionariosRepository>(), null, null),
          ),
        ),

        /// Añade control [CreadorTituloFormGroup()] al control 'bloques' del cuestionario y muestra widget [CreadorTituloCard]
        IconButton(
          icon: const Icon(Icons.format_size),
          tooltip: 'Agregar titulo',
          onPressed: () => agregarBloque(
            formController,
            animatedList,
            CreadorTituloController(),
          ),
        ),

        /// Muestra numero de bloque y las opciones de copiar, pegar y borrar bloque
        PopupMenuButton<int>(
          padding: const EdgeInsets.all(2.0),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 1,
              child: ListTile(
                /* 
                leading: const Icon(Icons.copy), */
                title: Consumer<int>(
                  builder: (context, value, child) => Text(
                    'Bloque número ${value + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                selected: true,
                onTap: () => {},
              ),
            ),
            PopupMenuItem(
              value: 2,
              child: ListTile(
                leading: Icon(
                  Icons.copy,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                title: Text('Copiar bloque',
                    style: TextStyle(color: Colors.grey[800])),
                selected: true,
                onTap: () => {
                  copiarBloque(formController),
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bloque Copiado'),
                    ),
                  ),
                  Navigator.pop(context),
                },
              ),
            ),
            PopupMenuItem(
              value: 3,
              child: ListTile(
                leading: Icon(
                  Icons.paste,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                title: Text('Pegar bloque',
                    style: TextStyle(color: Colors.grey[800])),
                selected: true,
                onTap: () => {
                  pegarBloque(formController, animatedList),
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bloque Pegado'),
                    ),
                  ),
                  Navigator.pop(context),
                },
              ),
            ),
            PopupMenuItem(
              value: 4,
              child: ListTile(
                  leading: Icon(
                    Icons.delete,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  selected: true,
                  title: Text('Borrar bloque',
                      style: TextStyle(color: Colors.grey[800])),
                  onTap: () => {
                        borrarBloque(formController, animatedList),
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Bloque eliminado'),
                          ),
                        ),
                        Navigator.pop(context),
                      }),
            ),
          ],
        ),
      ],
    );
  }

  /// Estos metodos son usados para mostrar en la UI, pero tambien acceden a los controles de [viewModel]
  /// Copia bloque.
  void copiarBloque(CreacionFormController formController) {
    formController.bloqueCopiado = controllerActual;
  }

  /// Pega bloque despues del bloque actual [formGroup]
  Future<void> pegarBloque(CreacionFormController formController,
      AnimatedListState animatedList) async {
    final bloqueCopiado = formController.bloqueCopiado;
    if (bloqueCopiado != null) {
      agregarBloque(formController, animatedList, bloqueCopiado.copy());
    }
  }

  /// Borra el bloque seleccionado [formGroup]
  void borrarBloque(
      CreacionFormController formController, AnimatedListState animatedList) {
    final index = formController.controllersBloques.indexOf(controllerActual);
    if (index == 0) return; //no borre el primer titulo
    /// Elimina de la lista en la pantalla
    animatedList.removeItem(
      index,
      (context, animation) => ControlWidgetAnimado(
        controller: controllerActual,
        animation: animation,
      ),
    );

    /// Elimina el control de los bloques de [viewModel]
    formController.borrarBloque(controllerActual);
  }

  /// Agrega un bloque despues del seleccionado
  void agregarBloque(
    CreacionFormController formController,
    AnimatedListState animatedList,
    CreacionController nuevo,
  ) {
    /// Lo inserta en la lista de la UI
    animatedList.insertItem(
        formController.controllersBloques.indexOf(controllerActual) + 1);

    /// Lo elimina de los controles de [formController]
    formController.agregarBloqueDespuesDe(
      bloque: nuevo,
      despuesDe: controllerActual,
    );
  }
}

/// Widget que elige que Card mostrar dependiendo de tipo de formGroup que sea [controller]
///
///Se usa en la animatedList de creacion_form_page.dart.
class ControlWidget extends StatelessWidget {
  final CreacionController controller;

  const ControlWidget(this.controller, {Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    //TODO: hacer esta transformación sin duplicacion de codigo cuando
    // implementen https://github.com/dart-lang/language/issues/216 en dart
    final controller = this.controller;
    //pendejada para que dart pueda hacer el cast con los ifs solamente
    if (controller is CreadorTituloController) {
      return CreadorTituloCard(
          //Las keys se necesitan cuando tenemos una lista dinamica de elementos del mismo tipo en flutter
          key: ValueKey(controller),
          controller: controller);
    }
    if (controller is CreadorPreguntaController) {
      return CreadorSeleccionSimpleCard(
          key: ValueKey(controller), controller: controller);
    }
    if (controller is CreadorPreguntaCuadriculaController) {
      return CreadorCuadriculaCard(
          key: ValueKey(controller), controller: controller);
    }
    if (controller is CreadorPreguntaNumericaController) {
      return CreadorNumericaCard(
          key: ValueKey(controller), preguntaController: controller);
    }
    return Text(
        "error: el bloque $controller no tiene una card que lo renderice, por favor informe de este error");
  }
}

class ControlWidgetAnimado extends StatelessWidget {
  final Animation<double> animation;
  final CreacionController controller;

  const ControlWidgetAnimado({
    Key? key,
    required this.controller,
    required this.animation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: animation,
      child: ControlWidget(controller),
    );
  }
}
