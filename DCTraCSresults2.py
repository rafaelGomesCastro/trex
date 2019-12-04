#!/usr/bin/python
# encoding: utf-8

import time, operator
from sklearn.metrics import confusion_matrix
from sklearn.metrics import f1_score
from sklearn.metrics import recall_score
from sklearn import tree

from sklearn.neighbors import KNeighborsClassifier

from util import *
from roc_curve import *
from sys import argv, exit


def DCTracCS_results(dim_images):
    #methods=["DCTraCS_ULBP", "DCTraCS_RLBP","Eerman", "Fahad", "Soysal", "Zhang"]
    methods=["DCTraCS_ULBP", "DCTraCS_RLBP"]
    #classif=["svm", "rf", "knn"]
    classif=["svm", "rf"]
    times={}

    error={}

    cm={}
    scores={}
    f1={}
    recall={}
    for k in methods:
        scores[k]={}
        f1[k] = {}
        recall[k] = {}
        cm[k]={}
        error[k]={}

    print("\n\nFig. 5. Accuracy of classifiers.")
    for k in methods:
        #X, y, ppp = read_classes(k,dim_images)
        num_train = int(get_definitions("Classes","number_of_train_classes",dim_images))
        X_train, y_train, X_test, y_test, ppp = read_classes_train_test(k,num_train,dim_images)

        #for i in range(X_test[0].shape[1]):
        #    print(X_test[0][i], end=' ')

        #for i in range(len(X_test)):

#        for i in range(len(y_train)):
#            print(y_train[i],end=' ')
#        print('\n')
#        for i in range(len(y_test)):
#            print(y_test[i],end=' ')
#        exit(-1)

        n_repeats = int(get_definitions("Validation","n_repeats",dim_images))
        for cl in classif:
            scores[k][cl] = [0]*n_repeats
            f1[k][cl]     = [0]*n_repeats
            recall[k][cl] = [0]*n_repeats
            cm[k][cl]     = [0]*n_repeats
            error[k][cl]  = []

        for i in range(n_repeats):
            if i==0:
                print("\nCross validation (max="+str(n_repeats)+"): [ 1",end=' ')
            else:
                print(str(i+1),end=' ')

            #X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=float(get_definitions("Validation","test_size",dim_images)))

            for cl in classif:
                if cl=="rf":
                    # cria uma DT
                    clf  = tree.DecisionTreeClassifier()
                elif cl=="svm":
                    clf = svm.SVC(kernel='rbf', C=8192.0, gamma=8.0) #
                    #clf = GridSearch(X_train, y_train, debug)
                elif cl == "knn":
                    clf = KNeighborsClassifier(n_neighbors = 3)

                clf.fit(X_train, y_train)

                y_pred = []

                # Predicting and getting the time
                start = time.time() ####
                for j in range(len(X_test)):
                    y_pred_aux = [0,0,0,0]
                    for l in range(X_test[j].shape[0]):
                        y_pred_aux[int(clf.predict(X_test[j][l]))-1] += 1

                    max = 0
                    for l in range(1,len(y_pred_aux)):
                        if (y_pred_aux[l] > y_pred_aux[max]):
                            max = l

                    y_pred.append(max + 1)

                end = time.time() ####
                times[k,cl] = end-start
                scores[k][cl][i] = clf.score(X_test[j][0:4], y_pred)
                f1[k][cl][i] = f1_score(y_test, y_pred, average='macro', labels=np.unique(y_pred))
                recall[k][cl][i] = recall_score(y_test, y_pred, average='macro')

                #print(scores[k][cl][i])

                for ind in range(len(y_pred)):
                    if (y_pred[ind] != y_test[ind]):
                        error[k][cl].append(ind)

                cm[k][cl][i]=confusion_matrix(y_test, y_pred)

                #if (k == "DCTraCS_RLBP" and cl=="svm"):
                #    # Computes the confusion matrix (Fig. 7)
                #    cm=confusion_matrix(y_test, y_pred)
                ##cm=confusion_matrix(y_test, y_pred)
        print("]")
        for cl in classif:
            for i in range(n_repeats):
                print('Accuracy '+k+"("+cl+"): "+ "{0:.2f}".format(np.mean(scores[k][cl][i])*100) + "% (std="+"{0:.2f}".format(np.std(scores[k][cl][i])*100)+"%)")
                print('F1-Score '+k+"("+cl+"): "+ "{0:.2f}".format(np.mean(f1[k][cl][i])*100) + "% (std="+"{0:.2f}".format(np.std(f1[k][cl][i])*100)+"%)")
                print('Recall '  +k+"("+cl+"): "+ "{0:.2f}".format(np.mean(recall[k][cl][i])*100) + "% (std="+"{0:.2f}".format(np.std(recall[k][cl][i])*100)+"%)")

    print("\nFig. 6. ROC curve of DCTraCS using ULBP and SVM.")
    #show_roc(dim_images)

    bigger_score = 0.
    best_clf     = ''
    best_method  = ''
    best_it      = 0
    for k in methods:
        for cl in classif:
            for i in range(n_repeats):
                if (scores[k][cl][i] > bigger_score):
                    bigger_score = scores[k][cl][i]
                    best_clf = cl
                    best_method = k
                    best_it = i
    print("\n\nFig. 7. Confusion matrix of " + best_method + '(' + best_clf + ")\n")
    print_cm(cm[best_method][best_clf][best_it])

    print("\n\nFig. 8. Normalized classification time.\n")
    m = max(times.items(), key=operator.itemgetter(1))[0]
    for i in times:
        print(i[0]+"("+i[1]+"): "+"{0:.8f}".format(times[i]/times[m]))

#    for i in range(len(error[best_method][best_clf])):
#        print "tm"+str(i)+".png",
#    print

def main(argv):
    if (len(argv) != 2):
        print("Usage:", argv[0], "<dim_images>")
        exit(-1)

    dim_images = argv[1]

    DCTracCS_results(dim_images)

    return 0

if __name__ == "__main__":
    main(argv)


