#include <chrono>
#include <fstream>
#include <iostream>
#include <pthread.h>
#include <random>
#include <unistd.h>
#include <vector>
#include <semaphore.h>
#include "rand.hpp"
#define MAX_WAITING_TIME 5

using namespace std;
struct Group;
long long get_time();
void write_output(const string &output);

// int get_random_number(double lambda = 2.0)
// {
//     static thread_local std::random_device rd;
//     static thread_local std::mt19937 generator(rd());
//     std::poisson_distribution<int> poissonDist(lambda);
//     return std::max(1, poissonDist(generator));
// }
struct Operative
{
    int id;
    int group_id;
    int arrival_time;
    int state;

    Operative() : id(0), group_id(0), arrival_time(0), state(0) {}
    Operative(int id, int group_id, int arrival_time)
        : id(id), group_id(group_id), arrival_time(arrival_time), state(0) {}
};


int N, M, x, y;
vector<Operative> operatives;
vector<Group> groups;
vector<sem_t> ts;
vector<sem_t> grp_locks;
sem_t rd, wrt;
int group_completed = 0, reader = 0;

pthread_mutex_t output_lock;
auto start_time = chrono::high_resolution_clock::now();

struct Group
{
    int id;
    int num_operatives, operatives_completed;

    Group() : id(0), num_operatives(0), operatives_completed(0) {}
    Group(int id, int num_operatives) : id(id), num_operatives(num_operatives), operatives_completed(0) {}
};

long long get_time()
{
    auto end_time = chrono::high_resolution_clock::now();
    auto duration = chrono::duration_cast<chrono::milliseconds>(
        end_time - start_time);
    long long elapsed_time_ms = duration.count();
    return elapsed_time_ms;
}

void write_output(const string &output)
{
    pthread_mutex_lock(&output_lock);
    cout << output;
    pthread_mutex_unlock(&output_lock);
}

void init()
{
    for (int i = 0; i < N; ++i)
    {
        int group_id = i / M + 1;
        int arrival_time = get_random_number()%MAX_WAITING_TIME + 1;
        operatives.push_back(Operative(i + 1, group_id, arrival_time));
    }
    for (int i = 0; i < N / M; ++i)
        groups.push_back(Group(i + 1, M));

    ts.resize(4);
    for (int i = 0; i < 4; ++i)
        sem_init(&ts[i], 0, 1);
    grp_locks.resize(N / M);
    for (int i = 0; i < N / M; ++i)
        sem_init(&grp_locks[i], 0, 0);

    pthread_mutex_init(&output_lock, NULL);
    sem_init(&rd, 0, 1);
    sem_init(&wrt, 0, 1);
}

void *work(void *arg)
{
    Operative *op = (Operative *)arg;
    usleep(op->arrival_time * 1000);
    int station_id = op->id % 4 + 1;
    write_output("Operative " + to_string(op->id) + " has arrived at typewriting station at time " + to_string(get_time()) + "\n");
    sem_wait(&ts[station_id - 1]);
    usleep(x * 1000);
    write_output("Operative " + to_string(op->id) + " has completed document recreation at time " + to_string(get_time()) + "\n");
    groups[op->group_id - 1].operatives_completed++;
    bool is_group_complete = (groups[op->group_id - 1].operatives_completed == M);
    sem_post(&ts[station_id - 1]);

    if (is_group_complete)
        sem_post(&grp_locks[op->group_id - 1]);
    if(op->id % M == 0 ){
        sem_wait(&grp_locks[op->group_id - 1]);
        write_output("Unit " + to_string(op->group_id) + " has completed document recreation phase at time " + to_string(get_time()) + "\n");
        sem_wait(&wrt);
        usleep(y * 1000);
        write_output("Unit " + to_string(op->group_id) + " has completed intelligence distribution at time " + to_string(get_time()) + "\n");
        group_completed++;
        sem_post(&wrt);
    }
    return NULL;
}

void *intelligence_hub(void *arg)
{
    int *staff_id = (int *)arg;
    int length = get_random_number()%5+1;
    while (true)
    {
        int random_wait_time = get_random_number() % 5 + 1;
        usleep(random_wait_time * 1000);
        sem_wait(&rd);
        reader++;
        if (reader == 1)
            sem_wait(&wrt);
        sem_post(&rd);

        write_output(
            "Intelligence Hub " + to_string(*staff_id) + " began reviewing logbook at time " + to_string(get_time()) +
            ". Operation completed = " + to_string(group_completed) + "\n"
        ); 
        usleep(length * 1000);

        sem_wait(&rd);
        reader--;
        if (reader == 0)
            sem_post(&wrt);
        sem_post(&rd);
        if (group_completed == N / M)
            break;
    }
    return NULL;
}

int main(int argc, char *argv[])
{
    if (argc != 3)
    {
        cout << "Usage: ./a.out <input_file> <output_file>" << endl;
        return 1;
    }

    // Input redirection
    ifstream inputFile(argv[1]);
    streambuf *cinBuffer = cin.rdbuf();
    cin.rdbuf(inputFile.rdbuf());

    ofstream outputFile(argv[2]);
    streambuf *coutBuffer = cout.rdbuf();
    cout.rdbuf(outputFile.rdbuf());

    int staff_count = 2;
    cin >> N >> M >> x >> y;
    init();

    pthread_t operative_threads[N];
    pthread_t staff_thread[staff_count];
    int *staff_ids = new int[staff_count];
    for (int i = 0; i < staff_count; ++i){
        staff_ids[i] = i + 1;
        pthread_create(&staff_thread[i], NULL, intelligence_hub, &staff_ids[i]);
    }

    for (int i = 0; i < N; ++i){
        pthread_create(&operative_threads[i], NULL, work, &operatives[i]);
    }


    for (int i = 0; i < N; ++i)
        pthread_join(operative_threads[i], NULL);
    for (int i = 0; i < staff_count; ++i)
        pthread_join(staff_thread[i], NULL);
    delete[] staff_ids;

    sem_destroy(&rd);
    sem_destroy(&wrt);
    for (int i = 0; i < 4; ++i)
        sem_destroy(&ts[i]);
    for (int i = 0; i < N / M; ++i)
        sem_destroy(&grp_locks[i]);
    pthread_mutex_destroy(&output_lock);
    cin.rdbuf(cinBuffer);
    cout.rdbuf(coutBuffer);

    return 0;
}
