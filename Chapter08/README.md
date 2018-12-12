# Chapter 8
## The Target
After working through the wireframe, the next step is to start solidfying the target state you wish to construct.  Since a fair amount of the platform is dependent upon the use of events to communicate changes, having a solid understanding of event-driven architecture is a requirement.

Some of the pre-requisites for establishing the target state will be putting together a base network design that will accommodate the traffic anticipated for the platform, taking into account the need for other applications to leverage the same network backbone.  Another crucial piece of the design will come with the data integrations required to feed the data warehouse from sources such as the new Square point of sale machines as well as any new ticket sales via the Eventbrite API.

### Useful links:
- [Square API](https://docs.connect.squareup.com/api/connect/v2)
- [Eventbrite API](https://www.eventbrite.com/developer/v3/)
- [Event Sourcing](https://martinfowler.com/eaaDev/EventSourcing.html) via Martin Fowler
- [Event Sourcing Pattern](https://docs.microsoft.com/en-us/azure/architecture/patterns/event-sourcing) via Azure Architecture
- [CloudEvents](https://cloudevents.io/) open specification  
- [ARTS Data Warehouse Model](https://www.omg.org/retail/dwm.htm)
- [Azure Data Catalog](https://azure.microsoft.com/en-us/services/data-catalog/)
- [Azure SQL Data Warehouse Patterns and Anti-Patterns](https://blogs.msdn.microsoft.com/sqlcat/2017/09/05/azure-sql-data-warehouse-workload-patterns-and-anti-patterns/)
- [ASCII Art Generator](http://patorjk.com/software/taag/)