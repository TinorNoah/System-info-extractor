package main

import (
	"fmt"
	"os"
	"strings"
	"time"

	"github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/shirou/gopsutil/v3/cpu"
	"github.com/shirou/gopsutil/v3/disk"
	"github.com/shirou/gopsutil/v3/host"
	"github.com/shirou/gopsutil/v3/mem"
)

// Styles
var (
	subtle    = lipgloss.AdaptiveColor{Light: "#D9DCCF", Dark: "#383838"}
	highlight = lipgloss.AdaptiveColor{Light: "#874BFD", Dark: "#7D56F4"}
	special   = lipgloss.AdaptiveColor{Light: "#43BF6D", Dark: "#73F59F"}

	listStyle = lipgloss.NewStyle().
			Border(lipgloss.NormalBorder(), false, true, false, false).
			BorderForeground(subtle).
			MarginRight(2).
			Height(8).
			Width(30)

	listHeader = lipgloss.NewStyle().
			BorderStyle(lipgloss.NormalBorder()).
			BorderBottom(true).
			BorderForeground(subtle).
			MarginRight(2).
			Render

	docStyle = lipgloss.NewStyle().Padding(1, 2, 1, 2)
)

type tickMsg time.Time

type model struct {
	cpuPercent float64
	memPercent float64
	diskPercent float64
	hostInfo   *host.InfoStat
	err        error
}

func initialModel() model {
	h, _ := host.Info()
	return model{
		hostInfo: h,
	}
}

func (m model) Init() tea.Cmd {
	return tea.Batch(
		tickCmd(),
	)
}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		if msg.String() == "q" || msg.String() == "ctrl+c" {
			return m, tea.Quit
		}
	case tickMsg:
		c, _ := cpu.Percent(0, false)
		v, _ := mem.VirtualMemory()
		d, _ := disk.Usage("/")

		m.cpuPercent = c[0]
		m.memPercent = v.UsedPercent
		m.diskPercent = d.Percent
		return m, tickCmd()
	}
	return m, nil
}

func (m model) View() string {
	if m.err != nil {
		return fmt.Sprintf("Error: %v", m.err)
	}

	doc := strings.Builder{}

	// Header
	doc.WriteString(listHeader("System Monitor"))
	doc.WriteString("\n\n")

	// Host Info
	if m.hostInfo != nil {
		doc.WriteString(fmt.Sprintf("Hostname: %s\n", m.hostInfo.Hostname))
		doc.WriteString(fmt.Sprintf("OS:       %s %s\n", m.hostInfo.Platform, m.hostInfo.PlatformVersion))
		doc.WriteString(fmt.Sprintf("Kernel:   %s\n", m.hostInfo.KernelVersion))
		doc.WriteString(fmt.Sprintf("Uptime:   %d hours\n", m.hostInfo.Uptime/3600))
	}
	doc.WriteString("\n")

	// Metrics
	doc.WriteString(fmt.Sprintf("CPU:  %s\n", progress(m.cpuPercent)))
	doc.WriteString(fmt.Sprintf("RAM:  %s\n", progress(m.memPercent)))
	doc.WriteString(fmt.Sprintf("Disk: %s\n", progress(m.diskPercent)))

	doc.WriteString("\nPress 'q' to quit")

	return docStyle.Render(doc.String())
}

func progress(percent float64) string {
	w := 20
	c := int(percent / 100 * float64(w))
	if c > w {
		c = w
	}
	return fmt.Sprintf("[%s%s] %.1f%%", 
		string(repeat('=', c)), 
		string(repeat(' ', w-c)), 
		percent)
}

func repeat(r rune, n int) []rune {
	b := make([]rune, n)
	for i := range b {
		b[i] = r
	}
	return b
}

func tickCmd() tea.Cmd {
	return tea.Tick(time.Second, func(t time.Time) tea.Msg {
		return tickMsg(t)
	})
}

func main() {
	p := tea.NewProgram(initialModel())
	if _, err := p.Run(); err != nil {
		fmt.Printf("Alas, there's been an error: %v", err)
		os.Exit(1)
	}
}
