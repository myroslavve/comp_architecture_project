import java.util.ArrayList;
import java.util.Scanner;

class LineOccurrence {
    int lineIndex;
    int count;

    public LineOccurrence(int lineIndex, int count) {
        this.lineIndex = lineIndex;
        this.count = count;
    }
}

public class Main {

    public static void main(String[] args) {
        Scanner scanner = new Scanner(System.in);
        ArrayList<String> lines = new ArrayList<>();
        while (scanner.hasNextLine()) {
            String line = scanner.nextLine();
            if (line.length() <= 255) {
                lines.add(line);
            }
        }
        scanner.close();

        if (args.length < 1) {
            System.out.println("Please provide a substring to search for.");
            return;
        }
        String substring = args[0];

        ArrayList<LineOccurrence> occurrences = new ArrayList<>();
        for (int i = 0; i < lines.size(); i++) {
            int count = countOccurrences(lines.get(i), substring);
            occurrences.add(new LineOccurrence(i, count));
        }

        mergeSort(occurrences, 0, occurrences.size() - 1);

        for (LineOccurrence occurrence : occurrences) {
            System.out.println(occurrence.count + " " + occurrence.lineIndex);
        }
    }

    private static int countOccurrences(String str, String sub) {
        int count = 0;
        int fromIndex = 0;
        while ((fromIndex = str.indexOf(sub, fromIndex)) != -1) {
            count++;
            fromIndex += sub.length();
        }
        return count;
    }

    private static void mergeSort(ArrayList<LineOccurrence> occurrences, int left, int right) {
        if (left < right) {
            int middle = (left + right) / 2;
            mergeSort(occurrences, left, middle);
            mergeSort(occurrences, middle + 1, right);
            merge(occurrences, left, middle, right);
        }
    }

    private static void merge(ArrayList<LineOccurrence> occurrences, int left, int middle, int right) {
        int n1 = middle - left + 1;
        int n2 = right - middle;

        ArrayList<LineOccurrence> L = new ArrayList<>(n1);
        ArrayList<LineOccurrence> R = new ArrayList<>(n2);

        for (int i = 0; i < n1; ++i) {
            L.add(occurrences.get(left + i));
        }
        for (int j = 0; j < n2; ++j) {
            R.add(occurrences.get(middle + 1 + j));
        }

        int i = 0, j = 0;
        int k = left;
        while (i < n1 && j < n2) {
            if (L.get(i).count <= R.get(j).count) {
                occurrences.set(k, L.get(i));
                i++;
            } else {
                occurrences.set(k, R.get(j));
                j++;
            }
            k++;
        }

        while (i < n1) {
            occurrences.set(k, L.get(i));
            i++;
            k++;
        }

        while (j < n2) {
            occurrences.set(k, R.get(j));
            j++;
            k++;
        }
    }
}
