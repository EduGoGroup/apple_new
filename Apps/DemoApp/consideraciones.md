# Frontend:

## apple_new

Este proyecto apple_new, es un proyecto que generara aplicaciones para iphone/ipad/mac todos usando la ultima tecnologia de apple, con swifui, swiftdata, los sistemas operativos 26, con xcode 26, recordando que aunque tenga la base de datos desactualizada, estos son los ultimos sistemas operativo a trabajar, todos ellos con swift 6.2, como minimo, (ya estamos en 6.4 en beta imaginate), se debe recordar que nunca se debe crear parche o apagar mensaje como noinsolate, usar los mainactor cuando sea necesario, y siempre pensar en arquitectura limpia, modular, y manteniendo las reglas estrictira en concurrencia, con liquidglass y demas patrones, te hago todo este comentario, porque en versiones futuras de swift, hay cosas que van a deprecar, y como somos un proyecto limpio de cero, no es justificable, empezando a marcar cosas que en poco tiempo quedara deprecado, por eso mi insistencia de siempre mantener el prpyecto con las directivas actualizada, puedes siempre ayudarte con context7 o la documentacion de apple oficial


## kmp_new
ruta : /Users/jhoanmedina/source/EduGo/EduUI/kmp_new

Este es el proyecto front principal, todos los estandades de negocios, y patrones de diseños, empiezan aca, es como el conejillo de india, donde se trata de estandarizar patrones, es una aplicacion kotlin multiplataforma, donde su salida son:
* Android / iOS : estamos usando material designer 3.0, jetpack compact (o deberia ), el desarrollo, logica UI, de android sera la misma que se usara para iOS, se piensa asi, porque quien va a tener las ventajas especiales de ios, es este prpyecto apple_new, quienes tenga sistema operativo inferior a 26, usara esta aplicacion, por eso la necesidad (y seria bueno tener este punto en la memoria) de que apple_new, debe usar lo ultimo de lo ultimo
* Escritorio ; usando kotlin multiplaforma, con compose multiplataforma y materia designer, mismo principio, para que corraen todos los sistema operativo y usando algunos estandares de jetbrain, 
* Web : estamos usand wasm con kotlin multiplataforma, y material designer.

Ya que se debe estar pendiente del tamaño de las ventanas, hay 3 definiciones para que se adapte segun el tipo de pantalla, que es el mismo principio para la plataforma, tambien esta modular, y solo aquellos casos especiales segun tecnologia
Aca esta, es importante de fijarse los patrones,

# Backend:

## Proyectos compartidos

### Edugo-shared
ruta: /Users/jhoanmedina/source/EduGo/EduBack/edugo-shared

Este es un proyecto en golang que centraliza codigo en modulos para que las api las use y no repetir codigo, cada modulo, tendra su propio manejo de go.mod y manejo de tag/github release, para que los otros proyectos puedan acceder mediante go get, cuando se trabaja en local, se tiene el archivo go.work, que permite resolver el flujo local, si no estuviera ese archivo, las api para trabajar necesitaria que el codigo de shared se sincronice a github y se cree el release
Lo que quiere decir, que siempre siempre, cuando se termine un desarrollo, se debe subir a github y crear el github release del modulo afecto, debido a que las api, en el momento de hacer el cicd, necesitara resolver esa version nueva
Este proyecto aparte de compartir codigo en comun, es el resonsable de algunas logicas que necesite hacerse en la base de datos, y repositorios que afecte a algunas tablas, para  centrlizar la responsabilidad de esa logica en un solo sitio

### Edugo-infraestructura
ruta: /Users/jhoanmedina/source/EduGo/EduBack/edugo-infraestructura

Otro proyecto en golang, con el mismo principio de edugo-shared, codigo compartido, que se resuelve mediante go get, o go.work local, y que cuando se termine el desarollo se debe hacer el github release al modulo afectado
Es muy muy importante, porque aca esta la estructura de la base de datos, y de la migraciones necesaria, tambien estan las entidades en go,muy muy importante, porque si modificamos una tabla, y modificamos la entidad, (el deber ser) cuando una api consuma ese codigo, automaticamente tendra el cambio, en caso contrario, si el api tuviera su propia version de objeto entidad, tendremos problema en desactualizacion

### edugo-dev-environment
ruta: /Users/jhoanmedina/source/EduGo/EduBack/edugo-dev-environment

Es un proyecto especializado en crear ambiente, enfocado para cuando se quiera actualizar la base de datos, o instalar las api, etc etc, lo coloca aca, porque tenemos un principio, no existe codigo deprecado ni codigo por recompatibilidad, si necesitamos agregar un campo a una tabla, no vamos a crear un script con alter table, hasta que se diga lo contrario, se debe ir a edugo-infraestructura, modificar el script de creacion del objeto en cuestion, osea la tabla, actualizar edugo-dev-enviroment, y forzar la migracion para que borre y cree la base de datos, entonces si hay que hacer cambios en la estructura, si o si, se debe modificar en infraestructura, tanto el script de creacion de la tabla, tanto los script de datos, tanto las entidades en go, y segun la necesidad, se debe recrear la base de datos que este proyecto tiene un proyecto llamado migracion, o se conecta directamente a la base de datos de neon y hacer la actualizacion directamente

## API

### edugo-api-iam-platform
ruta: /Users/jhoanmedina/source/EduGo/EduBack/edugo-api-iam-platform

Esta api centraliza logica de autenticacion autorizacion, configuracion de plataforma, como la UI dinamica, los permisos, roles y demas, consume mucho los proyectos shared e infraestructura
Esta en golang, y se despliega en azure
Si necesitas correr esta api en local, debes buscar en el archivo .zed/debug.json y usar la configuracion de "Go: Debug main (CLOUD MODE - Neon)", ya que estan los valores necesario para correr.
Si necesitas consumir la api en azure la url es https://edugo-api-iam-platform.wittyhill-f6d656fb.eastus.azurecontainerapps.io
recordando que la api por estar free, tiene tiempo de inactividad, puedes ejecutar el sh /Users/jhoanmedina/source/EduGo/EduUI/kmp_new/warm-up-apis.sh


### edugo-api-admin-new
ruta: /Users/jhoanmedina/source/EduGo/EduBack/edugo-api-admin-new

Esta api centraliza logica de negocio del ecosistema que menos se consume, consume mucho los proyectos shared e infraestructura
Esta en golang, y se despliega en azure
Si necesitas correr esta api en local, debes buscar en el archivo .zed/debug.json y usar la configuracion de "Go: Debug main (CLOUD MODE - Neon/Atlas)", ya que estan los valores necesario para correr.
Si necesitas consumir la api en azure la url es https://edugo-api-admin-new.wittyhill-f6d656fb.eastus.azurecontainerapps.io
recordando que la api por estar free, tiene tiempo de inactividad, puedes ejecutar el sh /Users/jhoanmedina/source/EduGo/EduUI/kmp_new/warm-up-apis.sh

### EduBack/edugo-api-mobile-new
ruta: /Users/jhoanmedina/source/EduGo/EduBack/edugo-api-mobile-new

Esta api centraliza logica de negocio del ecosistema que menos se consume, consume mucho los proyectos shared e infraestructura
Esta en golang, y se despliega en azure
Si necesitas correr esta api en local, debes buscar en el archivo .zed/debug.json y usar la configuracion de "Go: Debug main (CLOUD MODE - Neon/Atlas)", ya que estan los valores necesario para correr.
Si necesitas consumir la api en azure la url es https://edugo-api-mobile-new.wittyhill-f6d656fb.eastus.azurecontainerapps.io
recordando que la api por estar free, tiene tiempo de inactividad, puedes ejecutar el sh /Users/jhoanmedina/source/EduGo/EduUI/kmp_new/warm-up-apis.sh
