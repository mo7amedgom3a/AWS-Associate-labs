# Week 2: Building Compute and Database Layers in AWS

This week focuses on implementing compute and database services within AWS, covering EC2 instances, containerization with Docker, and various AWS database options.

## Modules Covered

### Adding a Compute Layer Using Amazon EC2

**Learning Objectives:**
- Understand Amazon EC2 fundamentals and instance types
- Deploy a Django application using Docker containers
- Configure and use Docker Compose for multi-container applications
- Implement Nginx as a reverse proxy for Gunicorn
- Apply AWS Well-Architected Framework principles to compute services

**Key Topics:**
- EC2 instance sizing and selection
- Docker containerization basics
- Multi-container orchestration with Docker Compose
- Nginx configuration as reverse proxy
- Gunicorn application server setup
- Container networking and security
- EC2 instance management best practices

### Adding Database Layers with AWS Database Services

**Learning Objectives:**
- Compare and contrast AWS database offerings
- Implement PostgreSQL databases using Amazon RDS
- Understand connection pooling with Amazon RDS Proxy
- Work with NoSQL databases using Amazon DynamoDB
- Select appropriate purpose-built databases for specific workloads
- Plan and execute database migrations to AWS

**Key Topics:**
- Amazon RDS architecture and management
- RDS Proxy for efficient connection handling
- DynamoDB fundamentals and data modeling
- Purpose-built databases in AWS (Amazon Aurora, Neptune, etc.)
- Database migration strategies and tools
- High availability and disaster recovery for databases
- Performance optimization for AWS databases

## Hands-on Labs

1. **Django Application Deployment with Docker**
   - Containerizing a Django application
   - Setting up PostgreSQL in Docker
   - Configuring Docker Compose for multi-container deployment
   - Implementing Nginx as reverse proxy for Gunicorn

2. **Working with Amazon RDS**
   - Deploying and configuring PostgreSQL on RDS
   - Implementing connection pooling with RDS Proxy
   - Setting up backups and maintenance windows
   - Monitoring database performance

3. **DynamoDB and Purpose-Built Databases**
   - Creating and managing DynamoDB tables
   - Implementing efficient NoSQL data models
   - Exploring appropriate use cases for purpose-built databases
   - Performance testing and optimization

4. **Database Migration Workshop**
   - Using AWS Database Migration Service
   - Planning and executing database migrations
   - Validating data integrity post-migration
   - Implementing cutover strategies

## Resources

- [Amazon EC2 Documentation](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/concepts.html)
- [Docker Documentation](https://docs.docker.com/)
- [Amazon RDS User Guide](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Welcome.html)
- [Amazon DynamoDB Developer Guide](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Introduction.html)
- [AWS Database Migration Service](https://aws.amazon.com/dms/)

---

*The labs in this section build upon the foundation established in Week 1, introducing compute and database services that are essential for deploying complete applications in AWS.*
